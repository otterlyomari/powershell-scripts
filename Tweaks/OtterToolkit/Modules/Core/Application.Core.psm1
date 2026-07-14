#Requires -Version 7.0

<#
.SYNOPSIS
OtterToolkit application management core.

.DESCRIPTION
Provider-agnostic application management layer.
#>


#region Provider Discovery

function Get-ToolkitApplicationProviders {

    [CmdletBinding()]

    param()


    $Providers =
        New-Object System.Collections.Generic.List[object]


    $Commands =
        Get-Command `
            -Name "Get-*ProviderManifest" `
            -CommandType Function `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -ne "Get-ProviderManifest"
        }


    foreach ($Command in $Commands) {

        try {

            $Manifest =
                & $Command.Name


            if ($Manifest.Type -ne "PackageManager") {
                continue
            }


            $SafeName =
                $Manifest.Name -replace '\s',''


            $AvailabilityCommand =
                "Test-${SafeName}Available"


            $Available =
                $false


            if (
                Get-Command `
                    $AvailabilityCommand `
                    -ErrorAction SilentlyContinue
            ) {

                $Available =
                    [bool](
                        & $AvailabilityCommand
                    )

            }


            $Providers.Add(

                [PSCustomObject]@{

                    Name =
                        $Manifest.Name

                    Version =
                        $Manifest.Version

                    Backend =
                        $Manifest.Backend

                    Capabilities =
                        $Manifest.Capabilities

                    Available =
                        $Available

                }

            )

        }

        catch {

            Write-Verbose `
                "Failed loading provider: $($Command.Name)"

        }

    }


    return $Providers

}

#endregion



#region Search

function Search-ToolkitApplication {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]

        [string]
        $Query

    )


    $Results =
        New-Object System.Collections.Generic.List[object]


    foreach (
        $Provider in (
            Get-ToolkitApplicationProviders
        )
    ) {


        if (-not $Provider.Available) {
            continue
        }


        $SafeName =
            $Provider.Name -replace '\s',''


        $SearchFunction =
            "Search-${SafeName}Application"


        $Command =
            Get-Command `
                $SearchFunction `
                -ErrorAction SilentlyContinue


        if (-not $Command) {
            continue
        }


        try {

            foreach (
                $Item in (
                    & $Command.Name -Query $Query
                )
            ) {


                $Item.Provider =
                    $Provider.Name


                $Results.Add(
                    $Item
                )

            }

        }

        catch {

            Write-Verbose `
                "Search failed for $($Provider.Name)"

        }

    }


    return (
        $Results |
        Sort-Object Name
    )

}

#endregion



#region Installation

function Install-ToolkitApplication {

    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(Mandatory)]

        [string]
        $Id,


        [Parameter(Mandatory)]

        [string]
        $Provider

    )


    if (
        -not (
            $PSCmdlet.ShouldProcess(
                $Id,
                "Install using $Provider"
            )
        )
    ) {

        return

    }


    $SafeName =
        $Provider -replace '\s',''


    $Command =
        Get-Command `
            "Install-${SafeName}Application" `
            -ErrorAction SilentlyContinue


    if (-not $Command) {

        throw `
            "Provider does not support installation: $Provider"

    }


    & $Command.Name `
        -Id $Id

}

#endregion



#region Removal

function Remove-ToolkitApplication {

    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(Mandatory)]

        [string]
        $Id,


        [Parameter(Mandatory)]

        [string]
        $Provider

    )


    if (
        -not (
            $PSCmdlet.ShouldProcess(
                $Id,
                "Remove using $Provider"
            )
        )
    ) {

        return

    }


    $SafeName =
        $Provider -replace '\s',''


    $Command =
        Get-Command `
            "Remove-${SafeName}Application" `
            -ErrorAction SilentlyContinue


    if (-not $Command) {

        throw `
            "Provider does not support removal: $Provider"

    }


    & $Command.Name `
        -Id $Id

}

#endregion



#region Installed Applications

function Get-ToolkitInstalledApplications {

    [CmdletBinding()]

    param()


    $Applications =
        New-Object System.Collections.Generic.List[object]


    foreach (
        $Provider in (
            Get-ToolkitApplicationProviders
        )
    ) {


        if (-not $Provider.Available) {
            continue
        }


        $SafeName =
            $Provider.Name -replace '\s',''


        $Command =
            Get-Command `
                "Get-${SafeName}Applications" `
                -ErrorAction SilentlyContinue


        if (-not $Command) {
            continue
        }


        try {

            foreach (
                $App in (
                    & $Command.Name
                )
            ) {

                $Applications.Add(
                    $App
                )

            }

        }

        catch {

            Write-Verbose `
                "Failed querying $($Provider.Name)"

        }

    }


    return $Applications

}

#endregion



Export-ModuleMember -Function *