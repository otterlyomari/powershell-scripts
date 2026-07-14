#Requires -Version 7.0

<#
.SYNOPSIS
Logging system for WindowsToolkit.

.DESCRIPTION
Provides structured logging for toolkit actions.

Logs are stored locally and include timestamps,
severity levels, and messages.
#>


#region Initialization


function Get-LogDirectory {

    $Path =
        Get-ToolkitPath "Logs"


    if (-not (Test-Path $Path)) {

        New-Item `
            -Path $Path `
            -ItemType Directory `
            -Force |
            Out-Null
    }


    return $Path
}



function Get-LogFile {

    $Date =
        Get-Date -Format "yyyy-MM-dd"


    Join-Path `
        (Get-LogDirectory) `
        "WindowsToolkit-$Date.log"
}


#endregion



#region Logging


function Write-ToolkitLog {

    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet(
            "INFO",
            "WARNING",
            "ERROR",
            "DEBUG"
        )]
        [string]$Level = "INFO"
    )


    $Timestamp =
        Get-Date `
            -Format "yyyy-MM-dd HH:mm:ss"



    $Entry =
        "[$Timestamp] [$Level] $Message"



    Add-Content `
        -Path (Get-LogFile) `
        -Value $Entry



    switch ($Level) {

        "WARNING" {

            Write-Warning $Message

        }


        "ERROR" {

            Write-Error $Message

        }


        "DEBUG" {

            Write-Verbose $Message

        }


        default {

            Write-Host $Message

        }

    }

}


function Write-ToolkitInfo {

    param(
        [string]$Message
    )


    Write-ToolkitLog `
        -Message $Message `
        -Level INFO
}



function Write-ToolkitWarning {

    param(
        [string]$Message
    )


    Write-ToolkitLog `
        -Message $Message `
        -Level WARNING
}



function Write-ToolkitError {

    param(
        [string]$Message
    )


    Write-ToolkitLog `
        -Message $Message `
        -Level ERROR
}


#endregion



#region System Logging


function Start-ToolkitSession {

    Write-ToolkitInfo `
        "================================="


    Write-ToolkitInfo `
        "WindowsToolkit session started"


    Write-ToolkitInfo `
        "User: $env:USERNAME"


    Write-ToolkitInfo `
        "Computer: $env:COMPUTERNAME"


    Write-ToolkitInfo `
        "================================="
}



#endregion



Export-ModuleMember `
    -Function *