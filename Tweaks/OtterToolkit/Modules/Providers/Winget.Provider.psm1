#Requires -Version 7.0

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

$CommonProvider =
    Join-Path `
        $PSScriptRoot `
        "Common.Provider.psm1"


if (
    Test-Path $CommonProvider
) {

    Import-Module `
        $CommonProvider `
        -ErrorAction Stop

}
else {

    throw `
        "Common.Provider.psm1 is required."

}


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

    return [bool](
        Test-ProviderCommand "winget"
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

function Search-WingetPackages {

<#
.SYNOPSIS
Searches winget packages.

.DESCRIPTION
Internal helper used by package providers.

.PARAMETER Query
Search query.

.PARAMETER Source
Optional winget source.
#>


[CmdletBinding()]

param(

    [Parameter(Mandatory)]
    [string]
    $Query,


    [string]
    $Source

)



$Arguments =
@(
    "search",
    $Query,
    "--accept-source-agreements"
)



if ($Source) {

    $Arguments += @(
        "--source",
        $Source
    )

}



$Result =
    Invoke-ProviderCommand `
        -FilePath "winget" `
        -Arguments $Arguments



$Packages =
    New-Object `
        System.Collections.Generic.List[object]



foreach(
    $Line in (
        $Result.Output -split "`n"
    )
) {

    $Line =
        $Line.Trim()


    # Skip blank lines, the column header row, and the "----" divider.
    # Without this, winget's own "Name  Id  Version" header can match
    # the data regex below and produce a fake package entry.

    if (
        $Line -eq "" -or
        $Line -match "^Name\s+Id\s+Version" -or
        $Line -match "^-+$" -or
        $Line -match "^Windows Package Manager"
    ) {

        continue

    }


    #
    # Winget columns: Name  Id  Version  [Match]
    #
    # Version is a single non-whitespace token. Anything after it
    # (separated by 2+ spaces) is an optional 4th "Match" column
    # (e.g. "Tag: spotify", "Moniker: foo", "ProductCode: bar") and
    # must NOT be swallowed into Version.

    if (
        $Line -match
        "^(.+?)\s{2,}([A-Za-z0-9\.\-_]+)\s{2,}(\S+)(?:\s{2,}(.+))?$"
    )
    {


        $Packages.Add(

            [PSCustomObject]@{

                Name =
                    $Matches[1].Trim()

                Id =
                    $Matches[2].Trim()

                Version =
                    $Matches[3].Trim()

                MatchReason =
                    if ($Matches[4]) {
                        $Matches[4].Trim()
                    }
                    else {
                        $null
                    }

                Provider =
                    "Winget"

                Source =
                    $Source

                Installed =
                    $false

            }

        )

    }

}


return $Packages

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