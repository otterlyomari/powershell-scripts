# RTSS Bulk Game Exclusion Script (v2 - auto-detects Steam libraries)

# Creates an "OSD off" profile for every game .exe found across ALL your Steam
# library folders, auto-discovered from libraryfolders.vdf.

# IMPORTANT: Close RTSS completely before running this script.
# Run PowerShell as Administrator (Profiles folder is under Program Files).

# ---- CONFIG ----

$RTSSProfiles = "C:\Program Files (x86)\RivaTuner Statistics Server\Profiles"

$MinimumExecutableSize = 5MB

# ---- STATISTICS ----

$Stats = [ordered]@{
    LibrariesScanned = 0
    ExecutablesFound = 0
    ProfilesCreated  = 0
    ProfilesSkipped  = 0
    DuplicatesFound  = 0
}

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# ---- STEP 1: Discover Steam libraries ----

$LibraryPaths = @()
$SteamPath = $null

Write-Verbose "Searching for Steam installation..."

# Check registry first, but validate the path
$RegistrySteamPaths = @(
    'HKCU:\Software\Valve\Steam',
    'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'
)

foreach ($Key in $RegistrySteamPaths) {

    try {

        $RegPath = (Get-ItemProperty -Path $Key -ErrorAction Stop).SteamPath

        if ($RegPath -and (Test-Path (Join-Path $RegPath "steam.exe"))) {

            $SteamPath = $RegPath
            Write-Verbose "Valid Steam registry path found: $SteamPath"
            break

        }

        else {

            Write-Verbose "Registry path invalid: $RegPath"

        }

    }
    catch {

        Write-Verbose "Registry key unavailable: $Key"

    }
}


# If registry failed, check common locations
if (-not $SteamPath) {

    Write-Verbose "Checking common Steam locations..."

    $CommonSteamLocations = @(
        "${env:ProgramFiles(x86)}\Steam",
        "${env:ProgramFiles}\Steam",
        "C:\Steam",
        "D:\Steam",
        "E:\Steam",
        "F:\Steam",
        "G:\Steam",
        "H:\Steam"
    )


    foreach ($Location in $CommonSteamLocations) {

        if (Test-Path (Join-Path $Location "steam.exe")) {

            $SteamPath = $Location
            Write-Verbose "Found Steam: $SteamPath"
            break

        }

    }

}


if (-not $SteamPath) {

    throw "Unable to locate Steam installation."

}


$VdfPath = Join-Path $SteamPath "steamapps\libraryfolders.vdf"


if (-not (Test-Path $VdfPath)) {

    throw "libraryfolders.vdf not found:`n$VdfPath"

}


Write-Verbose "Reading Steam library database..."

$Content = Get-Content $VdfPath -Raw


foreach ($Match in [regex]::Matches(
    $Content,
    '"path"\s*"([^"]+)"'
)) {

    $LibraryRoot = $Match.Groups[1].Value -replace '\\\\','\'

    $Common = Join-Path $LibraryRoot "steamapps\common"


    if (Test-Path $Common) {

        Write-Verbose "Detected library: $Common"

        $LibraryPaths += $Common

    }

}


# Include primary library
$DefaultLibrary = Join-Path $SteamPath "steamapps\common"


if (
    (Test-Path $DefaultLibrary) -and
    ($LibraryPaths -notcontains $DefaultLibrary)
) {

    $LibraryPaths += $DefaultLibrary

}


$LibraryPaths = $LibraryPaths | Sort-Object -Unique

# ---- STEP 2: Template (same structure as your working GeometryDash.exe.cfg) ----
$templateContent = @"
[OSD]
EnableOSD=0
EnableBgnd=1
EnableFill=0
EnableStat=0
BaseColor=00FF8000
BgndColor=00000000
FillColor=80000000
PositionX=1
PositionY=1
ZoomRatio=2
CoordinateSpace=0
EnableFrameColorBar=0
FrameColorBarMode=0
RefreshPeriod=500
IntegerFramerate=1
MaximumFrametime=0
EnableFrametimeHistory=0
FrametimeHistoryWidth=-32
FrametimeHistoryHeight=-4
FrametimeHistoryStyle=0
ScaleToFit=0
[Statistics]
FramerateAveragingInterval=1000
PeakFramerateCalc=0
PercentileCalc=0
FrametimeCalc=0
PercentileBuffer=0
[Framerate]
Limit=0
LimitDenominator=1
LimitTime=0
LimitTimeDenominator=1
SyncDisplay=0
SyncScanline0=0
SyncScanline1=0
SyncPeriods=0
SyncLimiter=0
PassiveWait=1
ReflexSleep=0
ReflexSetLatencyMarker=1
"@

# ---- STEP 3: Discover Steam executables ----

if (-not (Test-Path $RTSSProfiles)) {
    throw "RTSS Profiles folder not found:`n$RTSSProfiles"
}

Write-Verbose "Beginning executable scan..."

$Executables = New-Object System.Collections.Generic.List[System.IO.FileInfo]

foreach ($Library in $LibraryPaths) {

    $Stats.LibrariesScanned++

    Write-Host "Scanning: $Library"

    Get-ChildItem `
        -Path $Library `
        -Recurse `
        -Filter *.exe `
        -File `
        -ErrorAction SilentlyContinue |

    Where-Object {
        $_.Length -ge $MinimumExecutableSize -and
        $_.Name -notmatch "^(unins|setup|installer|crash|launcher|unitycrashhandler)" -and 
        $_.FullName -notmatch "\\(redist|redistributables|support|tools|_CommonRedist)\\"
    } |

    ForEach-Object {
        $Executables.Add($_)
        Write-Verbose "Found executable: $($_.FullName)"
    }
}

$Stats.ExecutablesFound = $Executables.Count

Write-Host ""
Write-Host "Found $($Executables.Count) eligible executable(s)."
Write-Host ""



# ---- STEP 4: Generate RTSS exclusion profiles ----

$SeenExecutables = @{}

$Index = 0

foreach ($Executable in $Executables) {

    $Index++

    Write-Progress `
        -Activity "Creating RTSS exclusions" `
        -Status $Executable.Name `
        -PercentComplete (($Index / $Executables.Count) * 100)


    $ExeName = $Executable.Name


    # Detect duplicate executable names
    if ($SeenExecutables.ContainsKey($ExeName)) {

        $Stats.DuplicatesFound++

        Write-Warning "Duplicate executable skipped: $ExeName"
        Write-Verbose "Duplicate path: $($Executable.FullName)"

        continue
    }


    $SeenExecutables[$ExeName] = $true


    $TargetCfg = Join-Path $RTSSProfiles "$ExeName.cfg"


    if ((Test-Path $TargetCfg) -and (-not $Force)) {

        $Stats.ProfilesSkipped++

        Write-Verbose "Skipping existing profile: $TargetCfg"

        continue
    }


    if ($PSCmdlet.ShouldProcess(
        $TargetCfg,
        "Create RTSS exclusion profile"
    )) {

        Set-Content `
            -Path $TargetCfg `
            -Value $TemplateContent `
            -Encoding ASCII


        $Stats.ProfilesCreated++

        Write-Host "Created exclusion: $ExeName"
    }
}


Write-Progress `
    -Activity "Creating RTSS exclusions" `
    -Completed



# ---- STEP 5: Summary ----

$Stopwatch.Stop()

Write-Host ""
Write-Host "================================"
Write-Host " RTSS Bulk Exclusion Complete"
Write-Host "================================"
Write-Host ""

Write-Host "Libraries scanned : $($Stats.LibrariesScanned)"
Write-Host "Executables found : $($Stats.ExecutablesFound)"
Write-Host "Profiles created  : $($Stats.ProfilesCreated)"
Write-Host "Profiles skipped  : $($Stats.ProfilesSkipped)"
Write-Host "Duplicates found  : $($Stats.DuplicatesFound)"
Write-Host "Elapsed time      : $($Stopwatch.Elapsed)"

Write-Host ""
Write-Host "Restart RTSS for changes to apply."