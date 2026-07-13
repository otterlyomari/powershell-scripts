param(
    [Parameter(Mandatory)]
    [string]$InfName,

    [switch]$RemoveDevices
)

# Ensure we're running as Administrator
if (-not ([Security.Principal.WindowsPrincipal])))
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "Searching for driver '$InfName'..."

# Find the published OEM INF corresponding to the original INF
$driverInfo = pnputil /enum-drivers |
    Select-String -Pattern "Published Name|Original Name"

$oemInf = $null
$currentPublished = $null

foreach ($line in $driverInfo) {
    if ($line -match 'Published Name\s*:\s*(.+)$') {
        $currentPublished = $Matches[1].Trim()
    }
    elseif ($line -match 'Original Name\s*:\s*(.+)$') {
        if ($Matches[1].Trim().ToLower() -eq $InfName.ToLower()) {
            $oemInf = $currentPublished
            break
        }
    }
}

if (-not $oemInf) {
    throw "Driver '$InfName' was not found."
}

Write-Host "Found published driver: $oemInf"

if ($RemoveDevices) {
    Write-Host "Removing devices using this driver..."

    Get-PnpDevice | ForEach-Object {
        $driver = Get-PnpDeviceProperty `
            -InstanceId $_.InstanceId `
            -KeyName 'DEVPKEY_Device_DriverInfPath' `
            -ErrorAction SilentlyContinue

        if ($driver.Data -eq $oemInf) {
            Write-Host "Removing: $($_.FriendlyName)"
            pnputil /remove-device "$($_.InstanceId)"
        }
    }
}

Write-Host "Removing driver package..."
pnputil /delete-driver $oemInf /uninstall /force

Write-Host ""
Write-Host "Done."
Write-Host "A reboot may be required."