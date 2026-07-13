# RTSS Bulk Game Exclusion Script (v2 - auto-detects Steam libraries)
# Creates an "OSD off" profile for every game .exe found across ALL your Steam
# library folders, auto-discovered from libraryfolders.vdf.
#
# IMPORTANT: Close RTSS completely before running this script.
# Run PowerShell as Administrator (Profiles folder is under Program Files).

# ---- CONFIG ----
$rtssProfiles = "C:\Program Files (x86)\RivaTuner Statistics Server\Profiles"

# Path to your main Steam install (where libraryfolders.vdf lives).
# Change this if Steam itself is installed somewhere else.
$steamInstallPath = "F:\Steam"

# Skip exes under this size to avoid catching installers/crash handlers/etc.
$minSizeBytes = 5MB

# ---- STEP 1: Auto-detect all Steam library folders from libraryfolders.vdf ----
$vdfPath = Join-Path $steamInstallPath "steamapps\libraryfolders.vdf"

$libraryPaths = @()

if (Test-Path $vdfPath) {
    $vdfContent = Get-Content $vdfPath -Raw
    # Matches lines like: "path"		"C:\\Program Files (x86)\\Steam"
    $matches = [regex]::Matches($vdfContent, '"path"\s*"([^"]+)"')

    foreach ($m in $matches) {
        # VDF escapes backslashes as \\, so unescape them
        $rawPath = $m.Groups[1].Value -replace '\\\\', '\'
        $commonPath = Join-Path $rawPath "steamapps\common"
        if (Test-Path $commonPath) {
            $libraryPaths += $commonPath
        }
    }
} else {
    Write-Warning "Could not find libraryfolders.vdf at: $vdfPath"
    Write-Warning "Falling back to default library only."
}

# Always make sure the default library is included even if the vdf parse missed it
$defaultCommon = Join-Path $steamInstallPath "steamapps\common"
if ((Test-Path $defaultCommon) -and ($libraryPaths -notcontains $defaultCommon)) {
    $libraryPaths += $defaultCommon
}

$libraryPaths = $libraryPaths | Select-Object -Unique

if ($libraryPaths.Count -eq 0) {
    Write-Error "No Steam library folders found. Check `$steamInstallPath at the top of this script."
    exit 1
}

Write-Host "Found Steam library folders:"
$libraryPaths | ForEach-Object { Write-Host "  $_" }
Write-Host ""

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

# ---- STEP 3: Generate profiles ----
if (-not (Test-Path $rtssProfiles)) {
    Write-Error "RTSS Profiles folder not found at: $rtssProfiles"
    exit 1
}

$created = 0
$skipped = 0

foreach ($lib in $libraryPaths) {
    Get-ChildItem -Path $lib -Recurse -Filter *.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -ge $minSizeBytes } |
        ForEach-Object {
            $exeName = $_.Name
            $targetCfg = Join-Path $rtssProfiles "$exeName.cfg"

            if (Test-Path $targetCfg) {
                $skipped++
            } else {
                Set-Content -Path $targetCfg -Value $templateContent -Encoding ASCII
                Write-Host "Created exclusion: $exeName"
                $created++
            }
        }
}

Write-Host ""
Write-Host "Done. Created $created new exclusion profiles, skipped $skipped (already existed)."
Write-Host "Restart RTSS for the new profiles to take effect."# RTSS Bulk Game Exclusion Script (v2 - auto-detects Steam libraries)
# Creates an "OSD off" profile for every game .exe found across ALL your Steam
# library folders, auto-discovered from libraryfolders.vdf.
#
# IMPORTANT: Close RTSS completely before running this script.
# Run PowerShell as Administrator (Profiles folder is under Program Files).

# ---- CONFIG ----
$rtssProfiles = "C:\Program Files (x86)\RivaTuner Statistics Server\Profiles"

# Path to your main Steam install (where libraryfolders.vdf lives).
# Change this if Steam itself is installed somewhere else.
$steamInstallPath = "F:\Steam"

# Skip exes under this size to avoid catching installers/crash handlers/etc.
$minSizeBytes = 5MB

# ---- STEP 1: Auto-detect all Steam library folders from libraryfolders.vdf ----
$vdfPath = Join-Path $steamInstallPath "steamapps\libraryfolders.vdf"

$libraryPaths = @()

if (Test-Path $vdfPath) {
    $vdfContent = Get-Content $vdfPath -Raw
    # Matches lines like: "path"		"C:\\Program Files (x86)\\Steam"
    $matches = [regex]::Matches($vdfContent, '"path"\s*"([^"]+)"')

    foreach ($m in $matches) {
        # VDF escapes backslashes as \\, so unescape them
        $rawPath = $m.Groups[1].Value -replace '\\\\', '\'
        $commonPath = Join-Path $rawPath "steamapps\common"
        if (Test-Path $commonPath) {
            $libraryPaths += $commonPath
        }
    }
} else {
    Write-Warning "Could not find libraryfolders.vdf at: $vdfPath"
    Write-Warning "Falling back to default library only."
}

# Always make sure the default library is included even if the vdf parse missed it
$defaultCommon = Join-Path $steamInstallPath "steamapps\common"
if ((Test-Path $defaultCommon) -and ($libraryPaths -notcontains $defaultCommon)) {
    $libraryPaths += $defaultCommon
}

$libraryPaths = $libraryPaths | Select-Object -Unique

if ($libraryPaths.Count -eq 0) {
    Write-Error "No Steam library folders found. Check `$steamInstallPath at the top of this script."
    exit 1
}

Write-Host "Found Steam library folders:"
$libraryPaths | ForEach-Object { Write-Host "  $_" }
Write-Host ""

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

# ---- STEP 3: Generate profiles ----
if (-not (Test-Path $rtssProfiles)) {
    Write-Error "RTSS Profiles folder not found at: $rtssProfiles"
    exit 1
}

$created = 0
$skipped = 0

foreach ($lib in $libraryPaths) {
    Get-ChildItem -Path $lib -Recurse -Filter *.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -ge $minSizeBytes } |
        ForEach-Object {
            $exeName = $_.Name
            $targetCfg = Join-Path $rtssProfiles "$exeName.cfg"

            if (Test-Path $targetCfg) {
                $skipped++
            } else {
                Set-Content -Path $targetCfg -Value $templateContent -Encoding ASCII
                Write-Host "Created exclusion: $exeName"
                $created++
            }
        }
}

Write-Host ""
Write-Host "Done. Created $created new exclusion profiles, skipped $skipped (already existed)."
Write-Host "Restart RTSS for the new profiles to take effect."