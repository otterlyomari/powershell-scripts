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
Scoop application provider.

.DESCRIPTION
Provides Scoop integration for OtterToolkit.

Scoop is a command-line installer for Windows
applications and developer tools.

This module abstracts Scoop commands behind
the OtterToolkit provider interface.

Requires:
- Scoop package manager

.NOTES
Part of OtterToolkit application providers.
#>


#region Provider Metadata


function Get-ScoopProviderManifest {

    <#
    .SYNOPSIS
    Returns Scoop provider metadata.
    #>

    [PSCustomObject]@{

        Name =
            "Scoop"

        Type =
            "PackageManager"

        Version =
            "1.0.0"

        Executable =
            "scoop"

        Description =
            "Scoop package manager provider."

    }

}


#endregion



#region Availability


function Test-ScoopAvailable {

    <#
    .SYNOPSIS
    Tests if Scoop is installed.
    #>


    [CmdletBinding()]

    param()


    return (
        Test-ProviderCommand `
            "scoop"
    )

}



function Get-ScoopExecutable {

    <#
    .SYNOPSIS
    Returns Scoop executable path.
    #>


    Get-ProviderExecutable `
        "scoop"

}


#endregion



#region Search


function Search-ScoopApplication {

    <#
    .SYNOPSIS
    Searches Scoop packages.

    .PARAMETER Query
    Package search term.

    .EXAMPLE
    Search-ScoopApplication git
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
            Test-ScoopAvailable
        )
    ) {

        throw `
            "Scoop is not available."

    }



    scoop search $Query

}


#endregion



#region Installed Applications


function Get-ScoopApplications {

    <#
    .SYNOPSIS
    Lists installed Scoop applications.
    #>


    [CmdletBinding()]

    param()



    if (
        -not (
            Test-ScoopAvailable
        )
    ) {

        throw `
            "Scoop is not available."

    }



    scoop list

}


#endregion



#region Installation


function Install-ScoopApplication {

    <#
    .SYNOPSIS
    Installs a Scoop application.

    .PARAMETER Id
    Scoop package name.

    .EXAMPLE
    Install-ScoopApplication git
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
            "Install using Scoop"
        )
    ) {


        Write-ToolkitInfo `
            "Installing $Id using Scoop."



        scoop install $Id



        Write-ToolkitInfo `
            "Installation completed: $Id"

    }

}



function Update-ScoopApplication {

    <#
    .SYNOPSIS
    Updates a Scoop application.

    .PARAMETER Id
    Application name.
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
            "Update using Scoop"
        )
    ) {


        scoop update $Id

    }

}



function Update-AllScoopApplications {

    <#
    .SYNOPSIS
    Updates all Scoop applications.
    #>


    [CmdletBinding(
        SupportsShouldProcess
    )]

    param()



    if (
        $PSCmdlet.ShouldProcess(
            "Installed Scoop applications",
            "Update all"
        )
    ) {


        scoop update *

    }

}


#endregion



#region Buckets


function Get-ScoopBuckets {

    <#
    .SYNOPSIS
    Lists configured Scoop buckets.
    #>


    [CmdletBinding()]

    param()


    scoop bucket list

}



function Add-ScoopBucket {

    <#
    .SYNOPSIS
    Adds a Scoop bucket.

    .PARAMETER Name
    Bucket name.
    #>


    [CmdletBinding(
        SupportsShouldProcess
    )]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Name

    )


    if (
        $PSCmdlet.ShouldProcess(
            $Name,
            "Add Scoop bucket"
        )
    ) {

        scoop bucket add $Name

    }

}


#endregion



Export-ModuleMember -Function *