#Requires -Version 7.0

<#
.SYNOPSIS
Application management UI.

.DESCRIPTION
Interactive CLI frontend for application
searching, installing, and removing.

Uses Application.Core as backend.
#>

#region Dependencies


$BaseUIPath =
Join-Path `
    $PSScriptRoot `
    "OtterToolkit.UI.psm1"


$CorePath =
Join-Path `
    $PSScriptRoot `
    "..\Core\Application.Core.psm1"



if (-not (Test-Path $BaseUIPath)) {

    throw `
    "OtterToolkit.UI.psm1 is required."

}



if (-not (Test-Path $CorePath)) {

    throw `
    "Application.Core.psm1 is required."

}



Import-Module `
    $BaseUIPath `
    -Force



Import-Module `
    $CorePath `
    -Force



#endregion


#region Application Menu


function Start-ApplicationManager {


    while ($true) {


        $Menu = @{

            "1" = "Search Applications"

            "2" = "Installed Applications"

            "3" = "Package Managers"

            "4" = "Back"

        }



        $Choice =
            Show-ToolkitMenu `
                -Title "Applications" `
                -Options $Menu



        if (
            $Choice -eq "Exit" -or
            $Choice -eq "4"
        ) {

            break

        }



        switch ($Choice) {


            "1" {

                Show-ApplicationSearch

            }



            "2" {

                Show-InstalledApplications

            }



            "3" {

                Show-PackageManagers

            }


        }


    }

}


#endregion



#region Search


function Show-ApplicationSearch {


    $Query =
    Read-Host `
    "Search (B = Back)"



    if (
        [string]::IsNullOrWhiteSpace($Query)
    ) {

        return

    }



    if (
        $Query -eq "B" -or
        $Query -eq "b" -or
        $Query -eq "BACK" -or
        $Query -eq "back"
    ) {

        return

    }



    Write-Host ""

    Write-ToolkitInfo `
        "Searching providers..."



    $Results =
        Search-ToolkitApplication `
            -Query $Query



    if (
        -not $Results
    ) {

        Write-Warning `
            "No applications found."

        Pause

        return

    }



    $Index = 1


    $Lookup =
        @{}



    Clear-Host


    Write-Host "Search Results"
    Write-Host "==============="
    Write-Host ""



    foreach ($App in $Results) {


        Write-Host (
            "[$Index] {0} ({1})" -f
            $App.Name,
            $App.Provider
        )


        $Lookup[$Index] =
            $App



        $Index++

    }



    Write-Host ""

    Write-Host "[B] Back"



    $Selection =
        Read-Host `
        "Select (B = Back)"



    if (
        $Selection -eq "B" -or
        $Selection -eq "b"
    ) {

        return

    }



    if (
        $Lookup.ContainsKey($Selection)
    ) {


        Show-ApplicationDetails `
            $Lookup[$Selection]

    }


}



#endregion



#region Details


function Show-ApplicationDetails {


param(

    [Parameter(Mandatory)]

    $Application

)



Clear-Host



Write-Host "Application"
Write-Host "==========="

Write-Host ""



$Application |
Format-List



Write-Host ""



$Choice =
    Read-Host `
    "Install? Y/N"



if (
    $Choice -eq "Y" -or
    $Choice -eq "y"
) {


    Install-ToolkitApplication `
        -Id $Application.Id `
        -Provider $Application.Provider


}



Pause


}



#endregion



#region Installed


function Show-InstalledApplications {


Clear-Host


Write-ToolkitInfo `
"Checking installed applications..."



Get-ToolkitInstalledApplications |
Format-Table `
Name,
Provider,
Version `
-AutoSize



Pause


}



#endregion



#region Providers


function Show-PackageManagers {


Clear-Host


Write-Host "Package Managers"
Write-Host "================"
Write-Host ""



Get-ToolkitApplicationProviders |
Format-Table `
Name,
Version,
Available,
Backend `
-AutoSize



Pause


}



#endregion



Export-ModuleMember -Function *
