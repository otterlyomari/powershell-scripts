#Requires -Version 7.0

<#
.SYNOPSIS
Common provider utilities for OtterToolkit.

.DESCRIPTION
Provides shared helper functions used by OtterToolkit
application providers.

This module does not manage applications directly.
Instead, it provides common functionality such as:

- External command detection
- Safe command execution
- Download handling
- Temporary workspace management
- Installer execution
- Network validation

Providers such as Winget, Scoop, Steam, and GitHub
can consume these functions.
#>

#region Provider Metadata

function Get-ProviderManifest {

    <#
    .SYNOPSIS
    Returns the common provider manifest.

    .DESCRIPTION
    Provides metadata describing this module.

    .OUTPUTS
    PSCustomObject
    #>

    [PSCustomObject]@{

        Name = "Common"

        Type = "Utility"

        Version = "1.0.0"

        Description =
            "Shared provider utilities for OtterToolkit."

        Capabilities = @{

            CommandExecution = $true
            Downloads         = $true
            Installation      = $true
            Networking        = $true

        }

    }

}

#endregion


#region Command Helpers


function Test-ProviderCommand {

    <#
    .SYNOPSIS
    Tests whether an external command exists.

    .PARAMETER Command
    Command name to locate.

    .EXAMPLE
    Test-ProviderCommand winget
    #>

    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Command

    )


    return (
        Get-Command `
            $Command `
            -ErrorAction SilentlyContinue
    )

}

function Write-ToolkitInfo {

    param(
        [Parameter(Mandatory)]
        [string]
        $Message
    )

    Write-Host "[INFO] $Message"

}



function Write-ToolkitWarning {

    param(
        [Parameter(Mandatory)]
        [string]
        $Message
    )

    Write-Host "[WARN] $Message"

}

function Write-ToolkitError {

    param(
        [Parameter(Mandatory)]
        [string]
        $Message
    )


    Write-Host "[ERROR] $Message"

}


function Get-ProviderExecutable {

    <#
    .SYNOPSIS
    Returns the full path to an executable.

    .PARAMETER Command
    Executable name.

    .EXAMPLE
    Get-ProviderExecutable winget
    #>

    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Command

    )


    $Executable =
        Get-Command `
            $Command `
            -ErrorAction SilentlyContinue


    if ($Executable) {

        return $Executable.Source

    }


    return $null

}


#endregion


#region Process Execution


function Invoke-ProviderCommand {

    <#
    .SYNOPSIS
    Executes an external provider command.

    .DESCRIPTION
    Provides consistent command execution
    and captures output.

    .PARAMETER FilePath
    Executable path.

    .PARAMETER Arguments
    Command arguments.

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Invoke-ProviderCommand `
        -FilePath winget `
        -Arguments @("list")
    #>

    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $FilePath,


        [string[]]
        $Arguments = @()

    )


    Write-Verbose `
        "Executing: $FilePath $($Arguments -join ' ')"


    try {

        $ProcessInfo =
            [System.Diagnostics.ProcessStartInfo]::new()


        $ProcessInfo.FileName =
            $FilePath


        $ProcessInfo.Arguments =
            $Arguments -join " "


        $ProcessInfo.RedirectStandardOutput =
            $true


        $ProcessInfo.RedirectStandardError =
            $true


        $ProcessInfo.UseShellExecute =
            $false


        $ProcessInfo.CreateNoWindow =
            $true



        $Process =
            [System.Diagnostics.Process]::new()


        $Process.StartInfo =
            $ProcessInfo



        $Process.Start() | Out-Null


        $StdOut =
            $Process.StandardOutput.ReadToEnd()


        $StdErr =
            $Process.StandardError.ReadToEnd()


        $Process.WaitForExit()



        [PSCustomObject]@{

            ExitCode =
                $Process.ExitCode


            Success =
                ($Process.ExitCode -eq 0)


            Output =
                $StdOut


            Error =
                $StdErr

        }


    }

    catch {

        Write-ToolkitError `
            "Command execution failed: $($_.Exception.Message)"


        return [PSCustomObject]@{

            ExitCode = -1

            Success = $false

            Output = ""

            Error =
                $_.Exception.Message

        }

    }

}


#endregion


#region Download Helpers


function Test-InternetConnection {

    <#
    .SYNOPSIS
    Tests network connectivity.
    #>


    [CmdletBinding()]

    param()


    try {

        return (
            Test-Connection `
                -ComputerName "1.1.1.1" `
                -Count 1 `
                -Quiet
        )

    }

    catch {

        return $false

    }

}



function Get-ProviderTempDirectory {

    <#
    .SYNOPSIS
    Creates and returns the provider temporary directory.
    #>


    [CmdletBinding()]

    param()


    $Path =
        Join-Path `
            $env:TEMP `
            "OtterToolkit"



    if (-not (
        Test-Path $Path
    )) {

        New-Item `
            -Path $Path `
            -ItemType Directory `
            -Force |
        Out-Null

    }


    return $Path

}



function Remove-ProviderTempDirectory {

    <#
    .SYNOPSIS
    Removes the provider temporary directory.
    #>


    [CmdletBinding(
        SupportsShouldProcess
    )]

    param()


    $Path =
        Join-Path `
            $env:TEMP `
            "OtterToolkit"



    if (
        Test-Path $Path
    ) {

        if (
            $PSCmdlet.ShouldProcess(
                $Path,
                "Remove temporary directory"
            )
        ) {

            Remove-Item `
                $Path `
                -Recurse `
                -Force

        }

    }

}



function Invoke-ProviderDownload {

    <#
    .SYNOPSIS
    Downloads a file.

    .PARAMETER Uri
    Download URL.

    .PARAMETER Destination
    Output path.

    .EXAMPLE
    Invoke-ProviderDownload `
        -Uri "https://example.com/file.zip" `
        -Destination "C:\Temp\file.zip"
    #>


    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Uri,


        [Parameter(
            Mandatory
        )]

        [string]
        $Destination

    )


    if (-not (
        Test-InternetConnection
    )) {

        throw `
            "No internet connection available."

    }



    Write-Verbose `
        "Downloading $Uri"



    Invoke-WebRequest `
        -Uri $Uri `
        -OutFile $Destination `
        -UseBasicParsing

}


#endregion


#region Installer Helpers


function Invoke-ProviderInstaller {

    <#
    .SYNOPSIS
    Runs an installer.

    .DESCRIPTION
    Wrapper around Start-Process.

    .PARAMETER FilePath
    Installer executable.

    .PARAMETER Arguments
    Installer arguments.
    #>


    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $FilePath,


        [string]
        $Arguments = ""

    )


    if (
        $PSCmdlet.ShouldProcess(
            $FilePath,
            "Run installer"
        )
    ) {

        Start-Process `
            -FilePath $FilePath `
            -ArgumentList $Arguments `
            -Wait

    }

}


#endregion


Export-ModuleMember -Function *
