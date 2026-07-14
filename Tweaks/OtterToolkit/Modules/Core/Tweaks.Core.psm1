#Requires -Version 7.0

<#
.SYNOPSIS
Windows tweak management engine.

.DESCRIPTION
Loads tweak definitions from JSON
and safely applies tweak actions.
#>


#region Paths

$TweakDirectory =
Join-Path `
    $PSScriptRoot `
    "..\..\Tweaks"


#endregion



#region Loading


function Get-TweakDefinitions {

    [CmdletBinding()]

    param()


    if (-not (Test-Path $TweakDirectory)) {

        throw `
        "Tweak directory missing: $TweakDirectory"

    }


    Get-ChildItem `
        -Path $TweakDirectory `
        -Filter "*.json" |
    ForEach-Object {


        try {

            Get-Content `
                -Path $_.FullName `
                -Raw |
            ConvertFrom-Json

        }

        catch {

            Write-Warning `
                "Failed loading tweak file: $($_.Name)"

        }


    }


}



#endregion



#region Actions


function Invoke-TweakRegistryAction {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
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
        -Force |
    Out-Null


}



function Invoke-TweakAction {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        $Action

    )


    switch ($Action.Type) {


        "Registry" {


            Invoke-TweakRegistryAction `
                -Action $Action


        }


        default {


            throw `
            "Unsupported tweak action type: $($Action.Type)"


        }


    }


}



#endregion



#region Public API


function Get-ToolkitTweaks {

    [CmdletBinding()]

    param()


    Get-TweakDefinitions


}



function Get-ToolkitTweak {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]
        $Name

    )


    Get-ToolkitTweaks |
    Where-Object {

        $_.Name -eq $Name

    }


}



function Invoke-ToolkitTweak {

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]

    param(

        [Parameter(Mandatory)]
        [string]
        $Name

    )


    $Tweak =
        Get-ToolkitTweak `
            -Name $Name



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
                -Action $Action


        }



        Write-ToolkitInfo `
            "Tweak applied successfully: $Name"


    }


}



#endregion



Export-ModuleMember `
    -Function *