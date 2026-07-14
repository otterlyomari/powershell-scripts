#Requires -Version 7.0

<#
.SYNOPSIS
Windows component management.

.DESCRIPTION
Provider-based abstraction layer for Windows components.

Supports:
- Optional Features
- Windows Capabilities

Provides discovery, enabling, and disabling.
#>


#region Providers


function Get-OptionalFeatureComponents {


    Get-WindowsOptionalFeature `
        -Online |
    ForEach-Object {


        [PSCustomObject]@{

            Name =
                $_.FeatureName

            DisplayName =
                $_.FeatureName

            Provider =
                "DISM.OptionalFeature"

            State =
                $_.State

            RestartNeeded =
                $_.RestartNeeded

        }

    }

}



function Get-CapabilityComponents {


    Get-WindowsCapability `
        -Online |
    ForEach-Object {


        [PSCustomObject]@{


            Name =
                $_.Name


            DisplayName =
                $_.Name


            Provider =
                "DISM.Capability"


            State =
                $_.State


            RestartNeeded =
                $false

        }

    }

}



#endregion



#region Discovery


function Get-ToolkitComponents {


    Write-ToolkitInfo `
        "Discovering Windows components."


    $Components =
        New-Object `
            System.Collections.Generic.List[object]



    foreach ($Provider in @(
        "OptionalFeature",
        "Capability"
    )) {


        switch ($Provider) {


            "OptionalFeature" {


                Get-OptionalFeatureComponents |
                ForEach-Object {

                    $Components.Add($_)

                }

            }


            "Capability" {


                Get-CapabilityComponents |
                ForEach-Object {

                    $Components.Add($_)

                }

            }

        }

    }


    return $Components |
    Sort-Object Name

}



function Get-ToolkitComponent {


    param(

        [Parameter(Mandatory)]
        [string]
        $Name

    )


    Get-ToolkitComponents |
    Where-Object {


        $_.Name -like "*$Name*" -or
        $_.DisplayName -like "*$Name*"


    }

}

function Search-ToolkitComponents {

    param(
        [string]$Query
    )


    Get-ToolkitComponents |
    Where-Object {

        $_.Name -like "*$Query*" -or
        $_.DisplayName -like "*$Query*"

    }

}



#endregion



#region Actions


function Enable-ToolkitComponent {


    [CmdletBinding(
        SupportsShouldProcess = $true
    )]

    param(

        [Parameter(Mandatory)]
        [string]
        $Name

    )


    $Components =
        Get-ToolkitComponent `
            $Name



    if (-not $Components) {

        throw `
            "Component not found: $Name"

    }



    if ($Components.Count -gt 1) {

        throw `
            "Multiple components found. Use a more specific name."

    }



    $Component =
        $Components[0]



    if (
        $PSCmdlet.ShouldProcess(
            $Component.Name,
            "Enable component"
        )
    ) {


        switch ($Component.Provider) {


            "DISM.OptionalFeature" {


                Enable-WindowsOptionalFeature `
                    -Online `
                    -FeatureName $Component.Name `
                    -All `
                    -NoRestart

            }



            "DISM.Capability" {


                Add-WindowsCapability `
                    -Online `
                    -Name $Component.Name

            }


        }



        Write-ToolkitInfo `
            "Enabled component: $($Component.Name)"

    }

}



function Disable-ToolkitComponent {


    [CmdletBinding(
        SupportsShouldProcess = $true
    )]

    param(

        [Parameter(Mandatory)]
        [string]
        $Name

    )



    $Components =
        Get-ToolkitComponent `
            $Name



    if (-not $Components) {

        throw `
            "Component not found: $Name"

    }



    if ($Components.Count -gt 1) {

        throw `
            "Multiple components found. Use a more specific name."

    }



    $Component =
        $Components[0]



    if (
        $PSCmdlet.ShouldProcess(
            $Component.Name,
            "Disable component"
        )
    ) {


        switch ($Component.Provider) {


            "DISM.OptionalFeature" {


                Disable-WindowsOptionalFeature `
                    -Online `
                    -FeatureName $Component.Name `
                    -NoRestart

            }


            "DISM.Capability" {


                Remove-WindowsCapability `
                    -Online `
                    -Name $Component.Name

            }

        }



        Write-ToolkitWarning `
            "Disabled component: $($Component.Name)"

    }

}



#endregion



Export-ModuleMember `
-Function *