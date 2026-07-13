#Requires -Version 7.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
Removes an installed application and associated leftovers.

.DESCRIPTION
Finds an application through Windows uninstall records,
runs the official uninstaller, then removes remaining files,
services, scheduled tasks, shortcuts, and registry entries.

.NOTES
Use -WhatIf before destructive operations.
Use -ListAll (optionally with -Name as a filter) to see everything this
script can discover, with its source hive, without removing anything.
Use -SearchAllDrives to also scan top-level install locations on every
fixed drive for leftover folders, not just the registry InstallLocation.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    # NOTE: no longer [Parameter(Mandatory)] -- -ListAll is a pure discovery
    # mode and shouldn't require a name. Manually validated below instead.
    [string]$Name,
    [switch]$IncludeUserData,
    [switch]$SearchAllDrives,

    # Diagnostic mode: lists every installed application this script can
    # see (across HKLM, HKCU, and every loaded HKU user hive), optionally
    # filtered by -Name, then exits without touching anything. Useful for
    # confirming the exact DisplayName/spelling/hive before doing a real
    # removal -- e.g. this would have immediately shown "Discord PTB" vs
    # "DiscordPTB" during the earlier troubleshooting.
    [switch]$ListAll
)

$ErrorActionPreference = "Continue"

if (-not $ListAll -and -not $Name) {
    throw "-Name is required unless -ListAll is specified."
}

#region Safety

$BlockedQueries = @(
    "Microsoft", "Google", "Adobe", "NVIDIA", "Intel",
    "AMD", "Apple", "Windows", "Driver", "Runtime", "SDK"
)

if (-not $ListAll -and $BlockedQueries -contains $Name) {
    throw "Generic vendor/component names are not allowed. Specify the full application name."
}

#endregion

#region Helpers

function Remove-IfExists {
    # FIX: This function calls $PSCmdlet.ShouldProcess() below, so it MUST
    # declare CmdletBinding(SupportsShouldProcess) itself. Without this,
    # $PSCmdlet is $null inside the function (it is not inherited from the
    # caller the way normal variables are), and calling a method on it
    # throws "You cannot call a method on a null-valued expression." the
    # first time this function runs. $WhatIfPreference IS inherited from
    # the calling scope, so -WhatIf on the outer script still flows through
    # correctly once this attribute is in place.
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path)

    if (-not (Test-Path $Path)) { return }

    Write-Host "Removing: $Path"

    if ($PSCmdlet.ShouldProcess($Path, "Delete")) {
        attrib -r -s -h $Path /S /D 2>$null
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Get-InstalledApplication {
    # FIX: Many apps (Discord, Slack, VS Code, and most other per-user
    # Squirrel/Electron installers) register ONLY under the current user's
    # HKCU hive, never under HKLM. This script requires elevation
    # (#Requires -RunAsAdministrator) for the service/registry cleanup
    # steps later on. If that elevation prompt is satisfied with a
    # *different* administrator account than the one the app was
    # installed under, "HKCU:" in the elevated process resolves to that
    # other account's hive -- so a per-user app can be completely
    # invisible to the original HKCU:-only search even though it's
    # sitting right there for the normal (unelevated) user.
    #
    # Fix: enumerate every loaded user hive under HKEY_USERS directly,
    # which is accessible regardless of which account you elevated as,
    # in addition to HKCU/HKLM.
    param(
        # Empty string matches everything ("*" + "" + "*" = "**", which
        # matches any string) -- this lets -ListAll call this function with
        # no filter to enumerate every installed application.
        [string]$ApplicationName = ""
    )

    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        # -WhatIf:$false is required here: New-PSDrive supports ShouldProcess,
        # and $WhatIfPreference is inherited from the script's own -WhatIf
        # switch. Without overriding it, this discovery-only step (creating a
        # read-only registry drive, not deleting anything) gets silently
        # skipped whenever the script itself is run with -WhatIf, which
        # breaks the HKU scan even in dry-run/preview mode.
        New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS -ErrorAction SilentlyContinue -WhatIf:$false | Out-Null
    }

    $locations = @(
        [PSCustomObject]@{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"; Source = "HKLM" }
        [PSCustomObject]@{ Path = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"; Source = "HKLM (WOW6432Node)" }
        [PSCustomObject]@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"; Source = "HKCU (elevated process)" }
    )

    # Add every real (non-.DEFAULT, non-Classes) loaded user SID hive.
    if (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue) {
        $userSidHives = Get-ChildItem "HKU:\" -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -match '^S-1-5-21-\d+-\d+-\d+-\d+$' }

        foreach ($hive in $userSidHives) {
            $locations += [PSCustomObject]@{
                Path   = "HKU:\$($hive.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
                Source = "HKU:\$($hive.PSChildName)"
            }
        }
    }

    $seen = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($location in $locations) {
        foreach ($app in (Get-ItemProperty $location.Path -ErrorAction SilentlyContinue)) {

            if (-not $app.DisplayName -or $app.DisplayName -notlike "*$ApplicationName*") { continue }

            # De-dupe in case the same app is visible through more than one
            # hive path (e.g. HKCU: and HKU:\<your own SID>).
            $key = "$($app.DisplayName)|$($app.PSPath)"
            if (-not $seen.Add($key)) { continue }

            [PSCustomObject]@{
                DisplayName     = $app.DisplayName
                DisplayVersion  = $app.DisplayVersion
                InstallLocation = $app.InstallLocation
                UninstallString = $app.UninstallString
                PSPath          = $app.PSPath
                Source          = $location.Source
            }
        }
    }
}

function Get-UninstallInfo {
    # FIX: Replaces Get-UninstallPath. The original returned only the exe
    # path, then the caller did
    #   $application.UninstallString.Substring($uninstaller.Length)
    # to get the arguments. But the regex strips surrounding quotes from
    # the exe path before returning it, so its .Length no longer lines up
    # with the position of the arguments in the original (quoted) string.
    # That silently mangled the uninstaller's argument list (e.g. left a
    # stray leading quote). Capturing both the path and the arguments as
    # separate regex groups avoids the mismatch entirely.
    param([string]$UninstallString)

    if ($UninstallString -match '^"?(?<exe>.+?\.exe)"?\s*(?<args>.*)$') {
        return [PSCustomObject]@{
            ExePath   = $Matches.exe
            Arguments = $Matches.args
        }
    }

    return $null
}

#endregion

#region List All (diagnostic mode)

if ($ListAll) {
    Write-Host "`n=== Installed Applications ($(if ($Name) { "matching '$Name'" } else { 'all' })) ===`n"

    $allApps = Get-InstalledApplication -ApplicationName $Name | Sort-Object DisplayName

    if ($allApps.Count -eq 0) {
        Write-Host "No applications found."
    }
    else {
        # FIX: -AutoSize -Wrap stretches every column to fit the single
        # longest value (usually a long InstallLocation path), which pads
        # every other row with a lot of empty whitespace. Fixed, truncated
        # widths keep the table compact regardless of outliers.
        $allApps | Format-Table -Property `
            @{ Label = "DisplayName"; Expression = { $_.DisplayName }; Width = 28 },
            @{ Label = "Version"; Expression = { $_.DisplayVersion }; Width = 12 },
            @{ Label = "Source"; Expression = { $_.Source }; Width = 24 },
            @{ Label = "InstallLocation"; Expression = {
                if ($_.InstallLocation -and $_.InstallLocation.Length -gt 40) {
                    "..." + $_.InstallLocation.Substring($_.InstallLocation.Length - 37)
                } else {
                    $_.InstallLocation
                }
            }; Width = 40 }
    }

    return
}

#endregion

#region Discovery

Write-Host "`n=== Searching Installed Applications ===`n"

$applications = @(Get-InstalledApplication -ApplicationName $Name)

if ($applications.Count -eq 0) {
    throw "No installed applications found matching '$Name'."
}

if ($applications.Count -gt 1) {
    Write-Host "Multiple applications found:`n"
    for ($i = 0; $i -lt $applications.Count; $i++) {
        Write-Host "[$i] $($applications[$i].DisplayName)"
    }
    $choice = Read-Host "`nSelect application number"
    $application = $applications[[int]$choice]
}
else {
    $application = $applications[0]
}

Write-Host "`nSelected:"
Write-Host "Name:    $($application.DisplayName)"
Write-Host "Version: $($application.DisplayVersion)"
Write-Host "Path:    $($application.InstallLocation)"
Write-Host "Remove:  $($application.UninstallString)"

#endregion

#region Confirmation

if (-not $PSCmdlet.ShouldProcess($application.DisplayName, "Remove application")) {
    return
}

#endregion

#region Uninstall

Write-Host "`n=== Running Official Uninstaller ===`n"

$uninstallInfo = Get-UninstallInfo $application.UninstallString

if ($uninstallInfo -and $PSCmdlet.ShouldProcess($application.DisplayName, "Run uninstaller")) {
    $startArgs = @{
        FilePath = $uninstallInfo.ExePath
        Wait     = $true
    }
    if ($uninstallInfo.Arguments) {
        $startArgs.ArgumentList = $uninstallInfo.Arguments
    }
    Start-Process @startArgs
}

#endregion

#region Cleanup Paths

Write-Host "`n=== Removing Installation Files ===`n"

$cleanupPaths = @()

if ($application.InstallLocation) {
    $cleanupPaths += $application.InstallLocation
}

if ($uninstallInfo -and $uninstallInfo.ExePath) {
    $cleanupPaths += Split-Path $uninstallInfo.ExePath
}

if ($SearchAllDrives) {
    # The registry only tells us about ONE install location. Games/apps
    # installed to a non-default drive (very common on a multi-drive setup)
    # can leave leftover folders elsewhere that InstallLocation never
    # mentions. This does a fast, TOP-LEVEL-ONLY scan of the common install
    # roots on every fixed drive -- not a full recursive disk crawl, which
    # would be far too slow to run per-uninstall.
    Write-Host "`n=== Searching All Drives ===`n"

    $nameVariants = @(
        $application.DisplayName
        $application.DisplayName.Replace(' ', '')
    ) | Select-Object -Unique

    $fixedDrives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty DeviceID

    foreach ($drive in $fixedDrives) {
        $searchRoots = @(
            "$drive\",
            "$drive\Program Files",
            "$drive\Program Files (x86)",
            "$drive\ProgramData"
        )

        foreach ($root in $searchRoots) {
            if (-not (Test-Path $root)) { continue }

            foreach ($variant in $nameVariants) {
                Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "*$variant*" } |
                    ForEach-Object {
                        Write-Host "Found on $drive`: $($_.FullName)"
                        $cleanupPaths += $_.FullName
                    }
            }
        }
    }
}

foreach ($path in $cleanupPaths | Select-Object -Unique) {
    Remove-IfExists $path
}

#endregion

#region User Data

if ($IncludeUserData) {
    Write-Host "`n=== Removing User Data ===`n"

    $possibleData = @(
        "$env:LOCALAPPDATA\$($application.DisplayName)",
        "$env:LOCALAPPDATA\$($application.DisplayName.Replace(' ',''))",
        "$env:APPDATA\$($application.DisplayName)",
        "$env:APPDATA\$($application.DisplayName.Replace(' ',''))"
    )

    foreach ($folder in $possibleData) {
        Remove-IfExists $folder
    }
}

#endregion

#region Services

Write-Host "`n=== Removing Related Services ===`n"

if ($application.InstallLocation) {
    Get-CimInstance Win32_Service |
        Where-Object { $_.PathName -like "*$($application.InstallLocation)*" } |
        ForEach-Object {
            Write-Host "Removing service: $($_.Name)"
            Stop-Service $_.Name -Force -ErrorAction SilentlyContinue
            sc.exe delete $_.Name | Out-Null
        }
}

#endregion

#region Registry

Write-Host "`n=== Removing Registry Entry ===`n"

if ($application.PSPath -and $PSCmdlet.ShouldProcess($application.DisplayName, "Remove uninstall registry entry")) {
    Remove-Item $application.PSPath -Recurse -Force
}

#endregion

Write-Host "`nCompleted."
Write-Host "A reboot may be required."