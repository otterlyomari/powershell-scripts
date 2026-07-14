#Requires -Version 7.0

<#
.SYNOPSIS
OtterToolkit Diagnostics Core.

.DESCRIPTION
Provides the backend diagnostic engine for
OtterToolkit.

This module contains no UI logic.

It exposes reusable diagnostic functions used by:

 • Terminal UI
 • Future WinUI frontend
 • Automation
 • Plugins

.NOTES
Part of the OtterToolkit Core.
#>

#region Helpers

function Test-ToolkitAdministrator {

<#
.SYNOPSIS
Returns whether PowerShell is running elevated.
#>

    [CmdletBinding()]
    param()

    $Identity =
        [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal =
        [Security.Principal.WindowsPrincipal]::new($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

}

function Convert-ToolkitBytes {

<#
.SYNOPSIS
Converts bytes into a readable string.
#>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [UInt64]
        $Bytes

    )

    switch ($Bytes) {

        {$_ -ge 1TB} {
            return "{0:N2} TB" -f ($Bytes / 1TB)
        }

        {$_ -ge 1GB} {
            return "{0:N2} GB" -f ($Bytes / 1GB)
        }

        {$_ -ge 1MB} {
            return "{0:N2} MB" -f ($Bytes / 1MB)
        }

        {$_ -ge 1KB} {
            return "{0:N2} KB" -f ($Bytes / 1KB)
        }

        default {
            return "$Bytes B"
        }

    }

}

function Invoke-ToolkitCommand {

<#
.SYNOPSIS
Safely executes a scriptblock.
#>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [scriptblock]
        $ScriptBlock

    )

    try {

        & $ScriptBlock

    }

    catch {

        Write-Verbose $_

        return $null

    }

}

#endregion

#region System Information

function Get-ToolkitOperatingSystem {

<#
.SYNOPSIS
Returns Windows operating system information.
#>

    [CmdletBinding()]
    param()


    $OS =
        Get-CimInstance Win32_OperatingSystem


    [PSCustomObject]@{

        ComputerName =
            $env:COMPUTERNAME

        Caption =
            $OS.Caption

        Version =
            $OS.Version

        Build =
            $OS.BuildNumber

        Architecture =
            $OS.OSArchitecture

        InstallDate =
            $OS.InstallDate

        LastBoot =
            $OS.LastBootUpTime

    }

}



function Get-ToolkitBootInformation {

<#
.SYNOPSIS
Returns system uptime information.
#>

    [CmdletBinding()]
    param()


    $OS =
        Get-CimInstance Win32_OperatingSystem


    $BootTime =
        $OS.LastBootUpTime


    $Uptime =
        New-TimeSpan `
            -Start $BootTime `
            -End (Get-Date)



    [PSCustomObject]@{

        BootTime =
            $BootTime

        Uptime =
            "{0} days {1} hours {2} minutes" -f `
            $Uptime.Days,
            $Uptime.Hours,
            $Uptime.Minutes

    }

}



function Get-ToolkitSystemInformation {

<#
.SYNOPSIS
Returns complete system information.

.DESCRIPTION
Combines OS, processor,
memory, and uptime information.

.EXAMPLE
Get-ToolkitSystemInformation
#>


    [CmdletBinding()]
    param()


    $OS =
        Get-ToolkitOperatingSystem


    $CPU =
        Get-CimInstance Win32_Processor |
        Select-Object -First 1


    $Memory =
        Get-CimInstance Win32_ComputerSystem


    $Boot =
        Get-ToolkitBootInformation



    [PSCustomObject]@{

        ComputerName =
            $OS.ComputerName


        OS =
            $OS.Caption


        Version =
            $OS.Version


        Build =
            $OS.Build


        Architecture =
            $OS.Architecture


        CPU =
            $CPU.Name


        CPU_Cores =
            $CPU.NumberOfCores


        CPU_Threads =
            $CPU.NumberOfLogicalProcessors


        RAM_GB =
            [math]::Round(
                $Memory.TotalPhysicalMemory / 1GB,
                2
            )


        BootTime =
            $Boot.BootTime


        Uptime =
            $Boot.Uptime


    }

}


#endregion

#region Hardware

function Get-ToolkitCPUInformation {

<#
.SYNOPSIS
Returns processor information.
#>

    [CmdletBinding()]
    param()


    Get-CimInstance Win32_Processor |
    Select-Object `
        Name,
        Manufacturer,
        NumberOfCores,
        NumberOfLogicalProcessors,
        MaxClockSpeed

}



function Get-ToolkitGPUInformation {

<#
.SYNOPSIS
Returns GPU information.
#>

    [CmdletBinding()]
    param()


    Get-CimInstance Win32_VideoController |
    Select-Object `
        Name,
        DriverVersion,
        VideoProcessor,
        AdapterRAM



}



function Get-ToolkitMemoryInformation {

<#
.SYNOPSIS
Returns physical memory modules.
#>

    [CmdletBinding()]
    param()


    Get-CimInstance Win32_PhysicalMemory |
    Select-Object `
        Manufacturer,
        PartNumber,
        Speed,

        @{Name="Capacity";Expression={
            Convert-ToolkitBytes $_.Capacity
        }}

}



function Get-ToolkitMotherboardInformation {

<#
.SYNOPSIS
Returns motherboard information.
#>

    [CmdletBinding()]
    param()


    $Board =
        Get-CimInstance Win32_BaseBoard


    [PSCustomObject]@{

        Manufacturer =
            $Board.Manufacturer

        Product =
            $Board.Product

        Serial =
            $Board.SerialNumber

    }

}



function Get-ToolkitBIOSInformation {

<#
.SYNOPSIS
Returns BIOS information.
#>

    [CmdletBinding()]
    param()


    $BIOS =
        Get-CimInstance Win32_BIOS


    [PSCustomObject]@{

        Manufacturer =
            $BIOS.Manufacturer

        Version =
            $BIOS.SMBIOSBIOSVersion

        ReleaseDate =
            $BIOS.ReleaseDate

        Serial =
            $BIOS.SerialNumber

    }

}



function Get-ToolkitDiskInformation {

<#
.SYNOPSIS
Returns physical disk health.
#>

    [CmdletBinding()]
    param()


    $Disks =
        Get-PhysicalDisk `
        -ErrorAction SilentlyContinue


    if (-not $Disks) {

        return

    }


    $Disks |
    Select-Object `
        FriendlyName,
        MediaType,
        BusType,
        HealthStatus,
        OperationalStatus,

        @{Name="Size";Expression={
            Convert-ToolkitBytes $_.Size
        }}

}



function Get-ToolkitBatteryInformation {

<#
.SYNOPSIS
Returns battery information.

.DESCRIPTION
Returns empty on desktop systems.
#>

    [CmdletBinding()]
    param()


    $Battery =
        Get-CimInstance Win32_Battery `
        -ErrorAction SilentlyContinue


    if (-not $Battery) {

        return $null

    }


    [PSCustomObject]@{

        Status =
            $Battery.Status

        Charge =
            "$($Battery.EstimatedChargeRemaining)%"

    }

}



function Get-ToolkitHardwareInformation {

<#
.SYNOPSIS
Returns complete hardware inventory.
#>

    [CmdletBinding()]
    param()


    [PSCustomObject]@{

        CPU =
            Get-ToolkitCPUInformation


        GPU =
            Get-ToolkitGPUInformation


        Memory =
            Get-ToolkitMemoryInformation


        Motherboard =
            Get-ToolkitMotherboardInformation


        BIOS =
            Get-ToolkitBIOSInformation


        Storage =
            Get-ToolkitDiskInformation


        Battery =
            Get-ToolkitBatteryInformation

    }

}


#endregion

#region Windows Health

function Invoke-ToolkitDISMScanHealth {

    [CmdletBinding()]

    param()


    Write-ToolkitInfo `
        "Running DISM ScanHealth."


    DISM `
        /Online `
        /Cleanup-Image `
        /ScanHealth

}



function Invoke-ToolkitDISMRestoreHealth {

    [CmdletBinding()]

    param()


    Write-ToolkitInfo `
        "Running DISM RestoreHealth."


    DISM `
        /Online `
        /Cleanup-Image `
        /RestoreHealth

}



function Invoke-ToolkitSFCScan {

    [CmdletBinding()]

    param()


    Write-ToolkitInfo `
        "Running System File Checker."


    sfc `
        /scannow

}



function Invoke-ToolkitWindowsHealthCheck {

    [CmdletBinding()]

    param()



    Write-ToolkitInfo `
        "Starting Windows health check."


    Write-Host ""
    Write-Host "================================="
    Write-Host " DISM Component Store Scan"
    Write-Host "================================="
    Write-Host ""


    Invoke-ToolkitDISMScanHealth



    Write-Host ""
    Write-Host "================================="
    Write-Host " DISM Component Repair"
    Write-Host "================================="
    Write-Host ""


    Invoke-ToolkitDISMRestoreHealth



    Write-Host ""
    Write-Host "================================="
    Write-Host " System File Checker"
    Write-Host "================================="
    Write-Host ""


    Invoke-ToolkitSFCScan



    Write-ToolkitInfo `
        "Windows health check completed."

}

#endregion

#region Event Logs

function Get-ToolkitCriticalEvents {

<#
.SYNOPSIS
Returns critical Windows events.

.DESCRIPTION
Searches System event logs for
critical and error events.

.PARAMETER Hours
How far back to search.

.PARAMETER Count
Maximum events returned.
#>


    [CmdletBinding()]

    param(

        [int]
        $Hours = 24,


        [int]
        $Count = 20

    )


    $StartTime =
        (Get-Date).AddHours(
            -$Hours
        )


    Get-WinEvent `
        -FilterHashtable @{

            LogName =
                "System"

            Level =
                1,2

            StartTime =
                $StartTime

        } `
        -MaxEvents $Count `
        -ErrorAction SilentlyContinue |
    Select-Object `
        TimeCreated,
        ProviderName,
        Id,
        LevelDisplayName,
        Message

}



function Get-ToolkitRecentWarnings {

<#
.SYNOPSIS
Returns recent warning events.
#>


    [CmdletBinding()]

    param(

        [int]
        $Hours = 24,


        [int]
        $Count = 20

    )


    $StartTime =
        (Get-Date).AddHours(
            -$Hours
        )


    Get-WinEvent `
        -FilterHashtable @{

            LogName =
                "System"

            Level =
                3

            StartTime =
                $StartTime

        } `
        -MaxEvents $Count `
        -ErrorAction SilentlyContinue |
    Select-Object `
        TimeCreated,
        ProviderName,
        Id,
        LevelDisplayName,
        Message

}



function Get-ToolkitHardwareEvents {

<#
.SYNOPSIS
Finds hardware related failures.

.DESCRIPTION
Looks for WHEA,
disk,
and hardware controller errors.
#>


    [CmdletBinding()]

    param(

        [int]
        $Hours = 72

    )


    $Events =
        Get-WinEvent `
            -FilterHashtable @{

                LogName =
                    "System"

                StartTime =
                    (Get-Date).AddHours(
                        -$Hours
                    )

            } `
            -ErrorAction SilentlyContinue



    $Keywords =
        @(
            "WHEA",
            "hardware",
            "disk",
            "controller",
            "corrected"
        )



    $Events |
    Where-Object {


        $Message =
            $_.Message



        foreach ($Keyword in $Keywords) {


            if (
                $Message -match $Keyword
            ) {

                return $true

            }

        }


        return $false

    } |
    Select-Object `
        TimeCreated,
        ProviderName,
        Id,
        LevelDisplayName,
        Message

}



function Get-ToolkitEventSummary {

<#
.SYNOPSIS
Returns diagnostic event summary.
#>


    [CmdletBinding()]

    param()


    $Critical =
        Get-ToolkitCriticalEvents `
            -Hours 24



    $Warnings =
        Get-ToolkitRecentWarnings `
            -Hours 24



    $Hardware =
        Get-ToolkitHardwareEvents



    [PSCustomObject]@{


        CriticalCount =
            @($Critical).Count


        WarningCount =
            @($Warnings).Count


        HardwareIssues =
            @($Hardware).Count


        CriticalEvents =
            $Critical


        WarningEvents =
            $Warnings


        HardwareEvents =
            $Hardware

    }

}


#endregion

#region Network Diagnostics

function Test-ToolkitInternetConnection {

    [CmdletBinding()]

    param()


    try {

        $Response =
            Invoke-WebRequest `
                -Uri "https://www.microsoft.com" `
                -Method Head `
                -TimeoutSec 5 `
                -UseBasicParsing `
                -ErrorAction Stop


        return $true

    }

    catch {

        return $false

    }

}



function Get-ToolkitVPNStatus {

    [CmdletBinding()]

    param()



    $VPNNames = @(
        "ProtonVPN",
        "NordVPN",
        "ExpressVPN",
        "Surfshark",
        "Mullvad",
        "Cloudflare WARP",
        "OpenVPN",
        "WireGuard",
        "Tailscale"
    )



    $Adapters =
        Get-NetAdapter `
            -ErrorAction SilentlyContinue |
        Where-Object {

            $_.Status -eq "Up" -and
            (
                $_.InterfaceDescription -match "VPN|WireGuard|TAP|Tunnel|Wintun"
            )

        }



    $Processes =
        Get-Process `
            -ErrorAction SilentlyContinue |
        Where-Object {

            $VPNNames -contains $_.ProcessName

        }



    $Detected = $false
    $Name = "None"



    if ($Adapters) {

        $Detected = $true

        $Name =
            $Adapters[0].InterfaceDescription

    }



    foreach ($VPN in $VPNNames) {

        if (
            Get-Process `
                -Name $VPN `
                -ErrorAction SilentlyContinue
        ) {

            $Detected = $true
            $Name = $VPN

        }

    }



    [PSCustomObject]@{

        Connected =
            $Detected

        Name =
            $Name

        Adapter =
            if ($Adapters) {
                $Adapters.Name -join ", "
            }
            else {
                "None"
            }

    }

}



function Get-ToolkitNetworkStatus {

    [CmdletBinding()]

    param()



    $Internet =
        Test-ToolkitInternetConnection


    $VPN =
        Get-ToolkitVPNStatus



    [PSCustomObject]@{

        Internet =
            $Internet

        VPNConnected =
            $VPN.Connected

        VPNName =
            $VPN.Name

        VPNAdapter =
            $VPN.Adapter

    }

}


#endregion

#region Performance Monitoring

function Get-ToolkitCPUUsage {

<#
.SYNOPSIS
Returns current CPU utilization.
#>

    [CmdletBinding()]

    param()


    $CPU =
        Get-Counter `
            "\Processor(_Total)\% Processor Time" `
            -ErrorAction SilentlyContinue



    if ($CPU) {


        [PSCustomObject]@{

            Usage =
                [math]::Round(
                    $CPU.CounterSamples.CookedValue,
                    2
                )

            Unit =
                "Percent"

        }

    }

}



function Get-ToolkitMemoryUsage {

<#
.SYNOPSIS
Returns memory utilization.
#>


    [CmdletBinding()]

    param()



    $Memory =
        Get-CimInstance `
            Win32_OperatingSystem



    $Total =
        $Memory.TotalVisibleMemorySize * 1KB


    $Free =
        $Memory.FreePhysicalMemory * 1KB


    $Used =
        $Total - $Free



    [PSCustomObject]@{


        TotalGB =
            [math]::Round(
                $Total / 1GB,
                2
            )


        UsedGB =
            [math]::Round(
                $Used / 1GB,
                2
            )


        FreeGB =
            [math]::Round(
                $Free / 1GB,
                2
            )


        UsagePercent =
            [math]::Round(
                (
                    $Used /
                    $Total
                ) * 100,
                2
            )

    }

}



function Get-ToolkitDiskActivity {

<#
.SYNOPSIS
Returns disk performance counters.
#>


    [CmdletBinding()]

    param()



    Get-Counter `
        "\PhysicalDisk(_Total)\% Disk Time" `
        -ErrorAction SilentlyContinue |
    Select-Object `
        Timestamp,
        @{Name="Usage";Expression={
            [math]::Round(
                $_.CounterSamples.CookedValue,
                2
            )
        }}

}



function Get-ToolkitTopProcesses {

<#
.SYNOPSIS
Returns processes using the most resources.
#>


    [CmdletBinding()]

    param(

        [int]
        $Count = 10

    )



    Get-Process |
    Sort-Object `
        CPU `
        -Descending |
    Select-Object `
        -First $Count `
        Name,
        Id,
        CPU,
        WorkingSet64 |
    ForEach-Object {


        [PSCustomObject]@{


            Name =
                $_.Name


            PID =
                $_.Id


            CPUSeconds =
                [math]::Round(
                    $_.CPU,
                    2
                )


            MemoryMB =
                [math]::Round(
                    $_.WorkingSet64 / 1MB,
                    2
                )

        }

    }

}



function Get-ToolkitServiceStatus {

<#
.SYNOPSIS
Returns important Windows services.
#>


    [CmdletBinding()]

    param()



    $ImportantServices =
        @(
            "WinDefend",
            "wuauserv",
            "BITS",
            "EventLog",
            "RpcSs"
        )



    Get-Service |
    Where-Object {

        $ImportantServices -contains $_.Name

    } |
    Select-Object `
        Name,
        DisplayName,
        Status

}



function Get-ToolkitPerformanceSnapshot {

<#
.SYNOPSIS
Returns complete performance snapshot.
#>


    [CmdletBinding()]

    param()



    [PSCustomObject]@{


        Timestamp =
            Get-Date


        CPU =
            Get-ToolkitCPUUsage


        Memory =
            Get-ToolkitMemoryUsage


        Disk =
            Get-ToolkitDiskActivity


        TopProcesses =
            Get-ToolkitTopProcesses


        Services =
            Get-ToolkitServiceStatus

    }

}


#endregion

#region Diagnostic Reports

function Get-ToolkitDiagnosticSnapshot {

<#
.SYNOPSIS
Creates a complete diagnostic snapshot.

.DESCRIPTION
Collects all diagnostic information
into a single object.
#>


    [CmdletBinding()]

    param()



    Write-ToolkitInfo `
        "Collecting diagnostic information."



    [PSCustomObject]@{


        Generated =
            Get-Date


        Computer =
            $env:COMPUTERNAME


        System =
            Get-ToolkitSystemInformation


        Hardware =
            Get-ToolkitHardwareHealth


        CPU =
            Get-ToolkitCPUUsage


        Memory =
            Get-ToolkitMemoryUsage


        Performance =
            Get-ToolkitPerformanceSnapshot


        Network =
            Get-ToolkitNetworkStatus


        CriticalEvents =
            Get-ToolkitCriticalEvents `
                -Hours 24


        HardwareEvents =
            Get-ToolkitHardwareEvents `
                -Hours 72

    }

}



function Export-ToolkitDiagnosticReport {

<#
.SYNOPSIS
Exports diagnostic report.

.PARAMETER Path
Output directory.
#>


    [CmdletBinding()]

    param(

        [string]
        $Path =
            ".\OtterToolkit_Diagnostics"

    )



    if (
        -not (
            Test-Path $Path
        )
    ) {

        New-Item `
            -ItemType Directory `
            -Path $Path |
        Out-Null

    }



    $Snapshot =
        Get-ToolkitDiagnosticSnapshot



 #
# Text Report
#

$TextPath =
    Join-Path `
        $Path `
        "Diagnostic_Report.txt"


$ReportText = @"
=================================
OtterToolkit Diagnostic Report
=================================

Generated:
$($Snapshot.Generated)

Computer:
$($Snapshot.Computer)


SYSTEM
---------------------------------

$(
$Snapshot.System |
Format-List |
Out-String
)


MEMORY
---------------------------------

$(
$Snapshot.Memory |
Format-List |
Out-String
)


NETWORK
---------------------------------

$(
$Snapshot.Network |
Format-List |
Out-String
)


CRITICAL EVENTS
---------------------------------

$(
$Snapshot.CriticalEvents |
Format-Table |
Out-String
)


HARDWARE EVENTS
---------------------------------

$(
$Snapshot.HardwareEvents |
Format-Table |
Out-String
)

"@


$ReportText |
Out-File `
    $TextPath `
    -Encoding UTF8

    #
    # JSON Report
    #

    $JsonPath =
        Join-Path `
            $Path `
            "Diagnostic_Report.json"



    $Snapshot |
    ConvertTo-Json `
        -Depth 8 |
    Out-File `
        $JsonPath `
        -Encoding UTF8



    Write-ToolkitInfo `
        "Diagnostic report exported."



    [PSCustomObject]@{


        TextReport =
            $TextPath


        JsonReport =
            $JsonPath

    }

}



function Invoke-ToolkitQuickDiagnostic {

<#
.SYNOPSIS
Runs a quick diagnostic scan.
#>


    [CmdletBinding()]

    param()



    Write-ToolkitInfo `
        "Running quick diagnostic."



    $Snapshot =
        Get-ToolkitDiagnosticSnapshot



    [PSCustomObject]@{


        Computer =
            $Snapshot.Computer


        CPU =
            $Snapshot.CPU


        Memory =
            $Snapshot.Memory


        Internet =
            $Snapshot.Network.Internet


        CriticalErrors =
            @(
                $Snapshot.CriticalEvents
            ).Count


        HardwareIssues =
            @(
                $Snapshot.HardwareEvents
            ).Count

    }

}


#endregion

Export-ModuleMember `
-Function *