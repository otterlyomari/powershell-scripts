#Requires -Version 7.0

<#
.SYNOPSIS
Microsoft Store application provider.

.DESCRIPTION
Provides Microsoft Store integration
through the winget msstore source.

Microsoft Store applications are handled
through the Winget provider backend.

.NOTES
Part of OtterToolkit application providers.
#>


#region Dependencies


$CommonProvider =
    Join-Path `
        $PSScriptRoot `
        "Common.Provider.psm1"


$WingetProvider =
    Join-Path `
        $PSScriptRoot `
        "Winget.Provider.psm1"



if (
    -not (
        Test-Path $CommonProvider
    )
) {

    throw `
        "Common.Provider.psm1 is required."

}



if (
    -not (
        Test-Path $WingetProvider
    )
) {

    throw `
        "Winget.Provider.psm1 is required."

}



Import-Module `
    $CommonProvider `
    -ErrorAction Stop


Import-Module `
    $WingetProvider `
    -ErrorAction Stop


#endregion



#region Metadata


function Get-MicrosoftStoreProviderManifest {


    [PSCustomObject]@{


        Name =
            "Microsoft Store"


        Type =
            "PackageManager"


        Version =
            "1.2.0"


        Backend =
            "Winget msstore"


        Capabilities = @(

            "Search"
            "Install"
            "Remove"
            "List"

        )


        Description =
            "Microsoft Store provider using Winget backend."

    }


}



#endregion



#region Availability


function Test-MicrosoftStoreAvailable {


    [CmdletBinding()]

    param()



    if (
        -not (
            Test-WingetAvailable
        )
    ) {

        return $false

    }



    try {

        $Sources =
            winget source list |
            Out-String


        return (
            $Sources -match "msstore"
        )

    }

    catch {

        return $false

    }


}



#endregion



#region Search


function Search-MicrosoftStoreApplication {


<#
.SYNOPSIS
Searches Microsoft Store applications.

.PARAMETER Query
Application search query.

.PARAMETER NoFallback
Restrict the search strictly to the msstore source; skip the
community "winget" source fallback used when msstore comes up empty.

.DESCRIPTION
msstore's search index is known to be unreliable - it can silently
return nothing for apps that are genuinely available (Spotify being
a common example), and its local cache can go stale. This function:

  1. Searches msstore normally.
  2. If empty, refreshes the msstore source cache and retries once.
  3. If still empty, falls back to the community "winget" source,
     since many Store apps are dual-listed there. Results from the
     fallback are clearly tagged so callers know they didn't come
     from the Store index directly.
  4. Ranks results so actual Name/Id matches outrank tag/moniker-only
     matches (e.g. unrelated tools tagged "spotify").
#>


    [CmdletBinding()]

    param(

        [Parameter(
            Mandatory
        )]

        [string]
        $Query,

        [switch]
        $NoFallback

    )



    if (
        -not (
            Test-MicrosoftStoreAvailable
        )
    ) {

        throw `
            "Microsoft Store unavailable."

    }



    Write-ToolkitInfo `
        "Searching Microsoft Store: $Query"



    $Results =
        Search-WingetPackages `
            -Query $Query `
            -Source "msstore"



    if (
        -not $Results
    ) {

        Write-ToolkitWarning `
            "No direct Store results for '$Query' - refreshing msstore cache and retrying."


        # Fix 2: msstore's local catalog cache can go stale and silently
        # return empty results for apps that are genuinely listed.

        winget source update --name msstore *> $null


        $Results =
            Search-WingetPackages `
                -Query $Query `
                -Source "msstore"

    }



    if (
        -not $Results
    ) {

        Write-ToolkitWarning `
            "No direct Store results. Trying broad search."



        $Token =
            $Query.Split(
                " "
            )[0]



        $Results =
            Search-WingetPackages `
                -Query $Token `
                -Source "msstore"

    }



    $FromFallbackSource =
        $false



    if (
        (-not $Results) -and
        (-not $NoFallback)
    ) {

        Write-ToolkitWarning `
            "msstore search for '$Query' came back empty - falling back to the community winget source."


        # Fix 3: some apps (Spotify being the classic example) are
        # unreliable or absent from the msstore search index but are
        # dual-listed in the community "winget" source.

        $Results =
            Search-WingetPackages `
                -Query $Query `
                -Source "winget"


        $FromFallbackSource =
            [bool] $Results

    }



    if (
        -not $Results
    ) {

        Write-ToolkitWarning `
            "No packages found."

        return

    }



    if ($FromFallbackSource) {

        Write-ToolkitWarning `
            "Results below came from the community winget source, not the Microsoft Store index directly."

    }



    $ProviderLabel =
        if ($FromFallbackSource) {
            "Microsoft Store (via winget fallback)"
        }
        else {
            "Microsoft Store"
        }


    $SourceName =
        if ($FromFallbackSource) {
            "winget"
        }
        else {
            "msstore"
        }



    $Normalized =
        foreach (
            $Package in $Results
        ) {


            [PSCustomObject]@{


                Name =
                    $Package.Name


                Id =
                    $Package.Id


                Version =
                    $Package.Version


                Provider =
                    $ProviderLabel


                Source =
                    $SourceName


                Installed =
                    $false


            }


        }



    # Rank actual Name/Id matches above tag/moniker-only matches
    # (e.g. unrelated tools that merely carry a "spotify" tag).

    $Normalized |
    Sort-Object {

        if ($_.Name -eq $Query) { 0 }
        elseif ($_.Name -like "*$Query*") { 1 }
        elseif ($_.Id -like "*$Query*") { 2 }
        else { 3 }

    }


}



#endregion



#region Installation


function Install-MicrosoftStoreApplication {


<#
.SYNOPSIS
Installs a Microsoft Store application.

.PARAMETER Id
Winget package ID.
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
            "Install Microsoft Store application"
        )
    ) {


        Write-ToolkitInfo `
            "Installing Microsoft Store application: $Id"



        winget install `
            --id $Id `
            --source msstore `
            --accept-source-agreements `
            --accept-package-agreements



        if (
            $LASTEXITCODE -ne 0
        ) {

            Write-ToolkitWarning `
                "Installation failed: $Id"


            return $false

        }



        Write-ToolkitInfo `
            "Installation complete: $Id"



        return $true

    }


}



#endregion



#region Removal


function Remove-MicrosoftStoreApplication {


<#
.SYNOPSIS
Removes a Microsoft Store application.

.PARAMETER Id
Winget package ID.
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
            "Remove Microsoft Store application"
        )
    ) {


        Write-ToolkitInfo `
            "Removing Microsoft Store application: $Id"



        winget uninstall `
            --id $Id `
            --source msstore



        if (
            $LASTEXITCODE -ne 0
        ) {

            Write-ToolkitWarning `
                "Removal failed: $Id"


            return $false

        }



        Write-ToolkitInfo `
            "Removal complete: $Id"



        return $true

    }


}



#endregion



#region Installed Applications


function Get-MicrosoftStoreApplications {


<#
.SYNOPSIS
Lists installed Microsoft Store applications.
#>


    if (
        -not (
            Test-MicrosoftStoreAvailable
        )
    ) {

        throw `
            "Microsoft Store unavailable."

    }



    $Applications =
        Get-WingetApplications



    foreach (
        $Application in $Applications
    ) {


        [PSCustomObject]@{


            Name =
                $Application.Name


            Id =
                $Application.Id


            Version =
                $Application.Version


            Provider =
                "Microsoft Store"


            Source =
                "msstore"


            Installed =
                $true


        }

    }


}



#endregion



Export-ModuleMember `
    -Function *