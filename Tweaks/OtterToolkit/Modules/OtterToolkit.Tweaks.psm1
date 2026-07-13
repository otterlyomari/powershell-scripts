#Requires -Version 7.0

<#
.SYNOPSIS
Windows tweak management engine.

.DESCRIPTION
Loads tweak definitions from JSON
and applies them safely.
#>


#region Paths


$TweakDirectory =
Join-Path `
    $PSScriptRoot `
    "..\Tweaks"



#endregion



#region Loading


function Get-TweakDefinitions {


    if (-not (Test-Path $TweakDirectory)) {

        throw `
        "Tweak directory missing."

    }


    Get-ChildItem `
        $TweakDirectory `
        -Filter *.json |
    ForEach-Object {


        Get-Content `
            $_.FullName `
            -Raw |
        ConvertFrom-Json


    }

}



#endregion



#region Actions


function Invoke-TweakRegistryAction {


    param(
        $Action
    )


    if (-not (Test-Path $Action.Path)) {

        New-Item `
            -Path $Action.Path `
            -Force |
            Out-Null

    }


    New-ItemProperty `
        -Path $Action.Path `
        -Name $Action.Name `
        -Value $Action.Value `
        -PropertyType $Action.Kind `
        -Force

}



function Invoke-TweakAction {


    param(
        $Action
    )


    switch ($Action.Type) {


        "Registry" {


            Invoke-TweakRegistryAction `
                $Action

        }


        default {


            throw `
            "Unknown tweak action type: $($Action.Type)"

        }

    }

}



#endregion



#region Public API


function Get-ToolkitTweaks {


    Get-TweakDefinitions

}



function Invoke-ToolkitTweak {


    [CmdletBinding(
        SupportsShouldProcess = $true
    )]

    param(

        [Parameter(Mandatory)]
        [string]$Name

    )


    $Tweak =
        Get-ToolkitTweaks |
        Where-Object {

            $_.Name -eq $Name

        }



    if (-not $Tweak) {

        throw `
        "Tweak not found: $Name"

    }



    if (
        $PSCmdlet.ShouldProcess(
            $Name,
            "Apply tweak"
        )
    ) {


        Write-ToolkitWarning `
            "Applying tweak: $Name"



        foreach ($Action in $Tweak.Actions) {


            Invoke-TweakAction `
                $Action

        }


        Write-ToolkitInfo `
            "Tweak applied: $Name"

    }

}



#endregion



Export-ModuleMember -Function *