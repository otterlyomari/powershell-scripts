#Requires -Version 7.0

<#
.SYNOPSIS
OtterToolkit tweak management UI.

.DESCRIPTION
Interactive CLI frontend for applying
Windows tweaks defined by Tweaks.Core.
#>


#region Dependencies

$CorePath =
Join-Path `
    $PSScriptRoot `
    "..\Core\Tweaks.Core.psm1"


$UIPath =
Join-Path `
    $PSScriptRoot `
    "OtterToolkit.UI.psm1"


$CorePath =
Resolve-Path `
    $CorePath `
    -ErrorAction Stop


$UIPath =
Resolve-Path `
    $UIPath `
    -ErrorAction Stop


Import-Module `
    $CorePath.Path `
    -Force


Import-Module `
    $UIPath.Path `
    -Force


#endregion



#region Main Menu

function Start-TweaksManager {

    while ($true) {


        $Tweaks =
            Get-ToolkitTweaks



        if (-not $Tweaks) {

            Write-Warning `
                "No tweaks found."

            Pause

            return

        }



        $Options =
            @{}


        $Index = 1



        foreach ($Tweak in $Tweaks) {


            $Options["$Index"] =
                $Tweak.Name


            $Index++

        }



        $Options["$Index"] =
            "Back"



        $Choice =
            Show-ToolkitMenu `
                -Title "Windows Tweaks" `
                -Options $Options



        if (
            $Choice -eq "Exit" -or
            $Choice -eq "$Index"
        ) {

            break

        }



        if (
            -not (
                $Choice -match '^\d+$'
            )
        ) {

            continue

        }



        $Selected =
            $Tweaks[
                [int]$Choice - 1
            ]



        if ($Selected) {

            Show-TweakDetails `
                -Tweak $Selected

        }


    }

}

#endregion



#region Details

function Show-TweakDetails {

param(

    [Parameter(Mandatory)]

    $Tweak

)


Clear-Host


Write-Host ""
Write-Host "================================="
Write-Host "            Tweak"
Write-Host "================================="
Write-Host ""


Write-Host (
    "Name: {0}" -f
    $Tweak.Name
)


if ($Tweak.Description) {

    Write-Host ""

    Write-Host (
        "Description: {0}" -f
        $Tweak.Description
    )

}


Write-Host ""


$Confirm =
    Read-Host `
    "Apply this tweak? (Y/N)"



if (
    $Confirm -eq "Y" -or
    $Confirm -eq "y"
) {


    Invoke-ToolkitTweak `
        -Name $Tweak.Name



    Write-Host ""

    Write-Host `
        "Tweak applied."

}


Pause

}

#endregion



Export-ModuleMember `
-Function *