#Requires -Version 7.0

<#
.SYNOPSIS
Application management module.

.DESCRIPTION
Provides package manager abstraction
for installing and managing applications.
#>


#region Providers


function Test-WingetAvailable {


    return (
        Get-Command winget `
            -ErrorAction SilentlyContinue
    )

}



function Test-ScoopAvailable {


    return (
        Get-Command scoop `
            -ErrorAction SilentlyContinue
    )

}



function Install-WingetApplication {


    param(
        [Parameter(Mandatory)]
        [string]$Id
    )


    Write-ToolkitInfo `
        "Installing via Winget: $Id"


    winget install `
        --id $Id `
        --accept-package-agreements `
        --accept-source-agreements

}



function Install-ScoopApplication {


    param(
        [Parameter(Mandatory)]
        [string]$Id
    )


    Write-ToolkitInfo `
        "Installing via Scoop: $Id"


    scoop install $Id

}


#endregion



#region Public API


function Get-ToolkitPackageManagers {


    $Managers = @()


    if (Test-WingetAvailable) {

        $Managers += "Winget"

    }


    if (Test-ScoopAvailable) {

        $Managers += "Scoop"

    }


    return $Managers

}



function Install-ToolkitApplication {


    [CmdletBinding(
        SupportsShouldProcess = $true
    )]

    param(

        [Parameter(Mandatory)]
        [string]$Id,


        [ValidateSet(
            "Winget",
            "Scoop"
        )]
        [string]$Provider = "Winget"

    )


    if (
        $PSCmdlet.ShouldProcess(
            $Id,
            "Install application"
        )
    ) {


        switch ($Provider) {


            "Winget" {


                Install-WingetApplication `
                    $Id

            }



            "Scoop" {


                Install-ScoopApplication `
                    $Id

            }

        }


        Write-ToolkitInfo `
            "Installation completed: $Id"

    }

}


#endregion

#region Data


$ApplicationDataPath =
Join-Path `
    $PSScriptRoot `
    "..\Data\Applications.json"



function Get-ApplicationDefinitions {


    if (-not (Test-Path $ApplicationDataPath)) {


        throw `
        "Application database missing."


    }


    Get-Content `
        $ApplicationDataPath `
        -Raw |
    ConvertFrom-Json

}



#endregion



#region Public Data API


function Get-ToolkitApplications {


    Get-ApplicationDefinitions

}



function Get-ToolkitApplicationsByCategory {


    param(
        [string]$Category
    )


    Get-ToolkitApplications |
    Where-Object {

        $_.Category -eq $Category

    }

}



#endregion


Export-ModuleMember -Function *