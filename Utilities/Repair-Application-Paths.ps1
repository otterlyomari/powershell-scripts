#Requires -Version 7.0

<#
.SYNOPSIS
    Repairs stale application registry paths.

.DESCRIPTION
    Searches application registry entries for invalid paths and can
    optionally repair them.

.PARAMETER Name
    Application name to search for.

.PARAMETER Fix
    Apply detected repairs.

.PARAMETER WhatIf
    Preview changes without modifying anything.

.EXAMPLE
    .\Repair-ApplicationPaths.ps1 -Name Steam

.EXAMPLE
    .\Repair-ApplicationPaths.ps1 -Name Steam -Fix

.EXAMPLE
    .\Repair-ApplicationPaths.ps1 -Name Steam -Fix -Verbose
#>

# ---- STEP 1: Initialize Script Parameters ----

[CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = "High"
)]

param(
    [Parameter(
        Mandatory = $true
    )]
    [string]$Name,

    [switch]$Fix
)


$RegistryLocations = @(
    "HKCU:\Software",
    "HKLM:\Software",
    "HKLM:\Software\WOW6432Node"
)


Write-Verbose "Searching for application: $Name"

# ---- STEP 2: Search Registry For Application Paths ----

$FoundEntries = New-Object System.Collections.Generic.List[object]

Write-Verbose "Searching uninstall registry entries..."

$SearchRoots = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)


foreach ($Root in $SearchRoots) {

    if (-not (Test-Path $Root)) {
        Write-Verbose "Registry location missing: $Root"
        continue
    }


    Get-ChildItem $Root -ErrorAction SilentlyContinue | ForEach-Object {

        try {

            $App = Get-ItemProperty $_.PSPath -ErrorAction Stop


            if ($App.DisplayName -and
                $App.DisplayName -like "*$Name*") {


                Write-Verbose "Found application: $($App.DisplayName)"


                $PossiblePaths = @(
                    $App.InstallLocation,
                    $App.DisplayIcon,
                    $App.UninstallString
                )


                foreach ($Path in $PossiblePaths) {

                    if (-not $Path) {
                        continue
                    }


                    # Remove command arguments from executable paths
                    $CleanPath = $Path -replace '"',''

                    if ($CleanPath -match "\.exe") {
                        $CleanPath = $CleanPath.Split(".exe")[0] + ".exe"
                    }


                    if ($CleanPath -match "^[A-Za-z]:\\") {

                        $Exists = Test-Path $CleanPath


                        $FoundEntries.Add([PSCustomObject]@{
                            Application = $App.DisplayName
                            RegistryKey = $_.PSPath
                            Value      = $CleanPath
                            Exists     = $Exists
                        })


                        if (-not $Exists) {
                            Write-Warning "Broken path detected:"
                            Write-Warning "  $CleanPath"
                        }
                    }
                }
            }

        }
        catch {
            Write-Verbose "Unable to read: $($_.PSPath)"
        }
    }
}


# ---- STEP 3: Output Results ----

if ($FoundEntries.Count -eq 0) {

    Write-Host "No matching applications found."

    exit
}


Write-Host ""
Write-Host "Application path scan complete:"
Write-Host ""

$FoundEntries |
Format-Table -AutoSize

# ---- STEP 4: Locate Valid Replacement Paths ----

$ReplacementPaths = New-Object System.Collections.Generic.List[string]

Write-Verbose "Searching for valid Steam installations..."

# Check common locations first
$SearchRoots = @(
    "${env:ProgramFiles(x86)}",
    "${env:ProgramFiles}",
    "D:\Steam",
    "E:\Steam",
    "F:\Steam",
    "G:\Steam",
    "H:\Steam",
    "I:\Steam",
    "J:\Steam",
    "K:\Steam",
    "L:\Steam",
    "M:\Steam",
    "N:\Steam",
    "O:\Steam",
    "P:\Steam",
    "Q:\Steam",
    "R:\Steam",
    "S:\Steam",
    "T:\Steam",
    "U:\Steam",
    "V:\Steam",
    "W:\Steam",
    "X:\Steam",
    "Y:\Steam",
    "Z:\Steam"
)


foreach ($Root in $SearchRoots) {

    if (-not (Test-Path $Root)) {
        continue
    }


    Write-Verbose "Scanning: $Root"


    try {

        Get-ChildItem `
            -Path $Root `
            -Filter steam.exe `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |

        ForEach-Object {

            $SteamRoot = Split-Path $_.FullName -Parent

            if ($ReplacementPaths -notcontains $SteamRoot) {

                Write-Verbose "Found Steam installation: $SteamRoot"

                $ReplacementPaths.Add($SteamRoot)
            }
        }

    }
    catch {

        Write-Verbose "Unable to scan: $Root"
    }
}



if ($ReplacementPaths.Count -eq 0) {

    Write-Warning "Could not locate a valid Steam installation."
    Write-Warning "No changes will be made."

    exit
}



Write-Host ""
Write-Host "Detected Steam installation(s):"

$Index = 1

foreach ($Path in $ReplacementPaths) {

    Write-Host "[$Index] $Path"

    $Index++
}



# Default to first detected installation
$NewSteamPath = $ReplacementPaths[0]


Write-Host ""
Write-Host "Selected replacement:"
Write-Host "  $NewSteamPath"