#Requires -Version 7.0

<#
.SYNOPSIS
Core functions for WindowsToolkit.

.DESCRIPTION
Provides shared functionality used throughout WindowsToolkit.
#>


#region Paths

function Get-ToolkitRoot {

    return Split-Path `
        -Parent `
        $PSScriptRoot
}


function Get-ToolkitPath {

    param(
        [Parameter(Mandatory)]
        [string]$ChildPath
    )

    Join-Path `
        (Get-ToolkitRoot) `
        $ChildPath
}

#endregion



#region System Checks


function Test-Administrator {

    $Identity =
        [Security.Principal.WindowsIdentity]::GetCurrent()


    $Principal =
        New-Object Security.Principal.WindowsPrincipal(
            $Identity
        )


    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}



function Get-WindowsVersion {

    Get-CimInstance `
        Win32_OperatingSystem |
        Select-Object `
            Caption,
            Version,
            BuildNumber
}



function Test-SupportedWindows {

    $OS = Get-WindowsVersion


    if ($OS.Caption -notmatch "Windows 10|Windows 11") {

        return $false
    }


    return $true
}


#endregion



#region Configuration


function Get-ToolkitConfig {

    $ConfigPath =
        Get-ToolkitPath `
            "Data\Config.json"


    if (-not (Test-Path $ConfigPath)) {

        return @{}
    }


    Get-Content `
        $ConfigPath `
        -Raw |
        ConvertFrom-Json
}


#endregion



#region Safety


function Confirm-ToolkitEnvironment {

    if (-not (Test-Administrator)) {

        throw `
        "WindowsToolkit requires Administrator privileges."
    }


    if (-not (Test-SupportedWindows)) {

        throw `
        "Unsupported Windows version."
    }

}


#endregion



Export-ModuleMember `
    -Function *