#Requires -Version 7.0

<#
.SYNOPSIS
Chocolatey application provider.

.DESCRIPTION
Provides Chocolatey integration for OtterToolkit.

This module abstracts Chocolatey package management
behind the OtterToolkit provider interface.

.NOTES
Part of OtterToolkit application providers.
#>


#region Dependencies

$CommonProvider =
    Join-Path `
        $PSScriptRoot `
        "Common.Provider.psm1"


if (
    Test-Path $CommonProvider
) {

    Import-Module `
        $CommonProvider `
        -Force

}

else {

    throw `
        "Common.Provider.psm1 is required."

}

#endregion



#region Provider Metadata

function Get-ChocolateyProviderManifest {

    [PSCustomObject]@{

        Name =
            "Chocolatey"

        Type =
            "PackageManager"

        Version =
            "1.1.0"

        Backend =
            "Chocolatey"

        Executable =
            "choco"

        Capabilities = @(

            "Search"
            "Install"
            "Remove"
            "List"
            "Update"

        )

        Description =
            "Chocolatey package manager provider."

    }

}

#endregion



#region Availability

function Test-ChocolateyAvailable {

    [CmdletBinding()]

    param()


    return [bool](
        Test-ProviderCommand `
            "choco"
    )

}



function Get-ChocolateyExecutable {

    Get-ProviderExecutable `
        "choco"

}

#endregion



#region Search

function Search-ChocolateyApplication {

    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Query

    )


    if (
        -not (
            Test-ChocolateyAvailable
        )
    ) {

        throw `
            "Chocolatey is unavailable."

    }



    $Output = 
        choco search `
            $Query `
            --limit-output



    foreach (
        $Line in $Output
    ) {


        if (
            $Line -match "\|"
        ) {


            $Parts =
                $Line.Split("|")


            [PSCustomObject]@{

                Name =
                    $Parts[0]

                Id =
                    $Parts[0]

                Version =
                    $Parts[1]

                Provider =
                    "Chocolatey"

                Installed =
                    $false

            }

        }

    }

}

#endregion



#region Installed Applications

function Get-ChocolateyApplications {

    [CmdletBinding()]

    param()



    if (
        -not (
            Test-ChocolateyAvailable
        )
    ) {

        throw `
            "Chocolatey is unavailable."

    }



    $Output =
        choco list `
            --local-only `
            --limit-output



    foreach (
        $Line in $Output
    ) {


        if (
            $Line -match "\|"
        ) {


            $Parts =
                $Line.Split("|")


            [PSCustomObject]@{

                Name =
                    $Parts[0]

                Id =
                    $Parts[0]

                Version =
                    $Parts[1]

                Provider =
                    "Chocolatey"

                Installed =
                    $true

            }

        }

    }

}

#endregion



#region Installation

function Install-ChocolateyApplication {

    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Id

    )


    if (
        $PSCmdlet.ShouldProcess(
            $Id,
            "Install using Chocolatey"
        )
    ) {


        Write-ToolkitInfo `
            "Installing $Id using Chocolatey."


        $Result =
            Invoke-ProviderCommand `
                -FilePath "choco" `
                -Arguments @(

                    "install"
                    $Id
                    "-y"

                )



        if (
            -not $Result.Success
        ) {

            throw `
                "Chocolatey installation failed: $($Result.Error)"

        }


        Write-ToolkitInfo `
            "Installation completed: $Id"

    }

}

#endregion



#region Removal

function Remove-ChocolateyApplication {

    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Id

    )


    if (
        $PSCmdlet.ShouldProcess(
            $Id,
            "Remove using Chocolatey"
        )
    ) {


        $Result =
            Invoke-ProviderCommand `
                -FilePath "choco" `
                -Arguments @(

                    "uninstall"
                    $Id
                    "-y"

                )



        if (
            -not $Result.Success
        ) {

            throw `
                "Chocolatey removal failed: $($Result.Error)"

        }

    }

}

#endregion



#region Update

function Update-ChocolateyApplication {

    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Id

    )


    if (
        $PSCmdlet.ShouldProcess(
            $Id,
            "Update using Chocolatey"
        )
    ) {


        choco upgrade `
            $Id `
            -y

    }

}



function Update-AllChocolateyApplications {

    [CmdletBinding(
        SupportsShouldProcess
    )]

    param()



    if (
        $PSCmdlet.ShouldProcess(
            "Installed packages",
            "Upgrade all Chocolatey packages"
        )
    ) {


        choco upgrade all -y

    }

}

#endregion



Export-ModuleMember -Function *