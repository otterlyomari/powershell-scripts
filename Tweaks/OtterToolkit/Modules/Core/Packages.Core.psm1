#Requires -Version 7.0

<#
.SYNOPSIS
Application management abstraction layer.

.DESCRIPTION
Provides a unified interface for installing,
searching, and managing applications through
OtterToolkit providers.

Providers handle the actual package manager
communication.

Supported providers may include:

- Winget
- Scoop
- Chocolatey
- Microsoft Store
- Steam
- Portable applications

This module acts as the backend API layer
for both the CLI interface and future WinUI
frontend.

.NOTES
Providers should expose functions following:

Get-<Provider>Applications
Install-<Provider>Application
Test-<Provider>Available
#>


#region Provider Discovery


function Get-ToolkitApplicationProviders {

    <#
    .SYNOPSIS
    Gets available application providers.

    .DESCRIPTION
    Searches loaded modules for providers
    capable of managing applications.
    #>


    [CmdletBinding()]

    param()


    $Providers =
        @()



    if (
        Get-Command `
            Test-WingetAvailable `
            -ErrorAction SilentlyContinue
    ) {

        $Providers += "Winget"

    }



    if (
        Get-Command `
            Test-ScoopAvailable `
            -ErrorAction SilentlyContinue
    ) {

        $Providers += "Scoop"

    }



    if (
        Get-Command `
            Test-ChocolateyAvailable `
            -ErrorAction SilentlyContinue
    ) {

        $Providers += "Chocolatey"

    }



    return $Providers

}



#endregion



#region Provider Validation


function Test-ToolkitApplicationProvider {

    <#
    .SYNOPSIS
    Tests whether an application provider exists.

    .PARAMETER Provider
    Provider name.

    .EXAMPLE
    Test-ToolkitApplicationProvider Winget
    #>


    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Provider

    )


    return (
        (Get-ToolkitApplicationProviders) -contains $Provider
    )

}


#endregion



#region Application Database


$ApplicationDataPath =
    Join-Path `
        $PSScriptRoot `
        "..\Data\Applications.json"



function Get-ApplicationDefinitions {

    <#
    .SYNOPSIS
    Loads application definitions.

    .DESCRIPTION
    Reads the optional application database.

    This allows the CLI and WinUI frontend
    to share the same application catalog.
    #>


    [CmdletBinding()]

    param()



    if (
        -not (
            Test-Path $ApplicationDataPath
        )
    ) {

        Write-ToolkitWarning `
            "Application database not found."


        return @()

    }



    Get-Content `
        $ApplicationDataPath `
        -Raw |
    ConvertFrom-Json

}



#endregion



#region Public Application API


function Get-ToolkitApplications {

    <#
    .SYNOPSIS
    Gets available applications.

    .DESCRIPTION
    Returns applications from the
    OtterToolkit database.

    .OUTPUTS
    PSCustomObject
    #>


    [CmdletBinding()]

    param()



    Get-ApplicationDefinitions

}



function Get-ToolkitApplicationsByCategory {

    <#
    .SYNOPSIS
    Filters applications by category.

    .PARAMETER Category
    Category name.

    .EXAMPLE
    Get-ToolkitApplicationsByCategory Browsers
    #>


    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Category

    )


    Get-ToolkitApplications |
    Where-Object {

        $_.Category -eq $Category

    }

}



function Find-ToolkitApplication {

    <#
    .SYNOPSIS
    Searches the application database.

    .PARAMETER Query
    Search text.

    .EXAMPLE
    Find-ToolkitApplication Firefox
    #>


    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Query

    )


    Get-ToolkitApplications |
    Where-Object {


        $_.Name -like "*$Query*" -or

        $_.Description -like "*$Query*"

    }

}



function Install-ToolkitApplication {

    <#
    .SYNOPSIS
    Installs an application.

    .DESCRIPTION
    Routes installation requests
    through the selected provider.

    .PARAMETER Id
    Provider package ID.

    .PARAMETER Provider
    Installation provider.

    .EXAMPLE
    Install-ToolkitApplication `
        -Id Mozilla.Firefox `
        -Provider Winget
    #>


    [CmdletBinding(
        SupportsShouldProcess
    )]


    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Id,


        [Parameter()]

        [string]
        $Provider = "Winget"

    )



    if (
        -not (
            Test-ToolkitApplicationProvider $Provider
        )
    ) {

        throw `
            "Application provider unavailable: $Provider"

    }



    if (
        $PSCmdlet.ShouldProcess(
            $Id,
            "Install application using $Provider"
        )
    ) {


        switch ($Provider) {


            "Winget" {

                Install-WingetApplication `
                    -Id $Id

                break

            }


            "Scoop" {

                Install-ScoopApplication `
                    -Id $Id

                break

            }


            "Chocolatey" {

                Install-ChocolateyApplication `
                    -Id $Id

                break

            }


            default {

                throw `
                "Provider does not support installation: $Provider"

            }

        }


        Write-ToolkitInfo `
            "Installed application: $Id"

    }

}



#endregion



Export-ModuleMember -Function *
