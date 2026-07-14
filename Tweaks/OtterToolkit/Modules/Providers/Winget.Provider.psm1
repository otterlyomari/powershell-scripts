#Requires -Version 7.0

$CommonProvider =
    Join-Path `
        $PSScriptRoot `
        "Common.Provider.psm1"


if (
    Test-Path $CommonProvider
) {

    Import-Module `
        $CommonProvider `
        -Force

}
else {

    throw `
        "Common.Provider.psm1 is required."

}

<#
.SYNOPSIS
Winget application provider.

.DESCRIPTION
Provides Windows Package Manager integration
for OtterToolkit.

This module acts as an abstraction layer between
OtterToolkit and the winget command line utility.

Requires:
- Windows Package Manager (winget)

.NOTES
Part of OtterToolkit application providers.
#>


#region Provider Metadata


function Get-WingetProviderManifest {

    <#
    .SYNOPSIS
    Returns provider metadata.
    #>


    [PSCustomObject]@{

        Name =
            "Winget"

        Type =
            "PackageManager"

        Version =
            "1.0.0"

        Executable =
            "winget"

        Description =
            "Windows Package Manager provider."

    }

}


#endregion



#region Availability


function Test-WingetAvailable {

    <#
    .SYNOPSIS
    Tests if winget is installed.
    #>


    [CmdletBinding()]

    param()


    return (
        Test-ProviderCommand `
            "winget"
    )

}



function Get-WingetExecutable {

    <#
    .SYNOPSIS
    Returns winget executable path.
    #>


    return (
        Get-ProviderExecutable `
            "winget"
    )

}


#endregion



#region Search


function Search-WingetApplication {

    <#
    .SYNOPSIS
    Searches winget packages.

    .PARAMETER Query
    Search term.

    .EXAMPLE
    Search-WingetApplication Firefox
    #>


    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Query

    )


    if (
        -not (
            Test-WingetAvailable
        )
    ) {

        throw `
            "Winget is not available."

    }



    $Result =
        Invoke-ProviderCommand `
            -FilePath "winget" `
            -Arguments @(
                "search",
                $Query
            )



    $Result.Output

}


#endregion



#region Installed Applications


function Get-WingetApplications {

    <#
    .SYNOPSIS
    Lists installed applications.

    .DESCRIPTION
    Uses winget list.
    #>


    [CmdletBinding()]

    param()



    if (
        -not (
            Test-WingetAvailable
        )
    ) {

        throw `
            "Winget is not available."

    }



    $Result =
        Invoke-ProviderCommand `
            -FilePath "winget" `
            -Arguments @(
                "list"
            )



    $Result.Output

}


#endregion



#region Installation


function Install-WingetApplication {

    <#
    .SYNOPSIS
    Installs an application.

    .PARAMETER Id
    Winget package ID.

    .EXAMPLE
    Install-WingetApplication `
        -Id Mozilla.Firefox
    #>


    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Id

    )



    if (
        $PSCmdlet.ShouldProcess(
            $Id,
            "Install using Winget"
        )
    ) {


        Write-ToolkitInfo `
            "Installing $Id using Winget."



        winget install `
            --id $Id `
            --accept-package-agreements `
            --accept-source-agreements


        Write-ToolkitInfo `
            "Installation completed: $Id"

    }

}



function Update-WingetApplication {

    <#
    .SYNOPSIS
    Updates an application.

    .PARAMETER Id
    Package ID.
    #>


    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Id

    )


    if (
        $PSCmdlet.ShouldProcess(
            $Id,
            "Update using Winget"
        )
    ) {


        winget upgrade `
            --id $Id `
            --accept-package-agreements `
            --accept-source-agreements

    }

}



function Update-AllWingetApplications {

    <#
    .SYNOPSIS
    Updates all winget packages.
    #>


    [CmdletBinding(
        SupportsShouldProcess
    )]

    param()



    if (
        $PSCmdlet.ShouldProcess(
            "Installed applications",
            "Upgrade all Winget packages"
        )
    ) {


        winget upgrade `
            --all `
            --accept-package-agreements `
            --accept-source-agreements

    }

}


#endregion



Export-ModuleMember -Function *
