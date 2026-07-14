```powershell
#Requires -Version 7.0

<#
.SYNOPSIS
OtterToolkit diagnostics interface.

.DESCRIPTION
Presentation layer for Diagnostics.Core.
#>

#region Dependencies

$CorePath =
Join-Path `
    $PSScriptRoot `
    "..\Core\Diagnostics.Core.psm1"

$CorePath =
Resolve-Path `
    $CorePath `
    -ErrorAction Stop

Import-Module `
    $CorePath.Path `
    -Force

#endregion


#region Dashboard

function Show-DiagnosticsDashboard {

Clear-Host

Write-Host ""
Write-Host "================================="
Write-Host "          Diagnostics"
Write-Host "================================="
Write-Host ""


$Info =
Get-ToolkitSystemInformation


Write-Host "System"
Write-Host "---------------------------------"

Write-Host (
    "Computer: {0}" -f
    $Info.ComputerName
)

Write-Host (
    "OS:       {0}" -f
    $Info.OS
)

Write-Host (
    "Build:    {0}" -f
    $Info.Build
)

Write-Host (
    "CPU:      {0}" -f
    $Info.CPU
)

Write-Host (
    "RAM:      {0} GB" -f
    $Info.RAM_GB
)



Write-Host "Network"
Write-Host "---------------------------------"


$Network =
Get-ToolkitAdvancedNetworkStatus


Write-Host (
    "Internet: {0}" -f
    $(if ($Network.Internet) {
        "Connected"
    }
    else {
        "Offline"
    })
)


Write-Host (
    "DNS:      {0}" -f
    $(if ($Network.DNS) {
        "OK"
    }
    else {
        "Failed"
    })
)


Write-Host (
    "Gateway:  {0}" -f
    $(if ($Network.Gateway) {
        "OK"
    }
    else {
        "Failed"
    })
)


Write-Host ""


if ($Network.VPN.Connected) {

    Write-Host (
        "VPN:      Connected ({0})" -f
        $Network.VPN.Name
    )

}
else {

    Write-Host "VPN:      Not detected"

}

Write-Host ""
Write-Host "Critical Events"
Write-Host "---------------------------------"


$Errors =
Get-ToolkitCriticalEvents `
    -Count 5


if ($Errors) {

    Write-Host (
        "Recent critical events: {0}" -f
        $Errors.Count
    )

}
else {

    Write-Host "No critical events found."

}


Write-Host ""

Pause

}

#endregion



#region Hardware

function Show-DiagnosticsHardware {

Clear-Host

Write-Host ""
Write-Host "Hardware Information"
Write-Host "---------------------------------"


Get-ToolkitHardwareInformation |
Format-List


Pause

}

#endregion



#region Windows Health

function Invoke-DiagnosticsWindowsHealth {

Clear-Host

Write-Host ""
Write-Host "Running Windows health scan..."
Write-Host ""


Invoke-ToolkitWindowsHealthCheck


Write-Host ""
Write-Host "Health scan completed."


Pause

}

#endregion



#region Event Viewer

function Show-DiagnosticsEvents {

Clear-Host

Write-Host ""
Write-Host "Recent Critical Events"
Write-Host "---------------------------------"
Write-Host ""


$Events =
Get-ToolkitCriticalEvents `
    -Count 20


if ($Events) {

    $Events |
    Format-Table `
        TimeCreated,
        ProviderName,
        Id `
        -AutoSize

}
else {

    Write-Host "No critical events found."

}


Pause

}

#endregion



#region Network Test

function Show-DiagnosticsNetwork {

Clear-Host


Write-Host ""
Write-Host "Network Diagnostics"
Write-Host "---------------------------------"


$Network =
Get-ToolkitAdvancedNetworkStatus



Write-Host ""
Write-Host "Connectivity"
Write-Host "---------------------------------"

$Network |
Select-Object `
    Internet,
    DNS,
    Gateway |
Format-List



Write-Host ""
Write-Host "VPN"
Write-Host "---------------------------------"

$Network.VPN |
Format-List



Write-Host ""
Write-Host "Latency"
Write-Host "---------------------------------"

$Network.Latency |
Format-Table `
    -AutoSize



Pause

}
#endregion



#region Export Report

function Invoke-DiagnosticsReportExport {

Clear-Host

Write-Host ""
Write-Host "Generating diagnostic report..."
Write-Host ""


Export-ToolkitDiagnosticReport


Write-Host ""
Write-Host "Report complete."


Pause

}

#endregion



#region Diagnostics Manager

function Start-DiagnosticsManager {

while ($true) {


    $Menu = @{

        "1" = "Dashboard"

        "2" = "Hardware Scan"

        "3" = "Windows Health"

        "4" = "Event Viewer"

        "5" = "Network Test"

        "6" = "Export Report"

        "7" = "Back"

    }



    $Choice =
        Show-ToolkitMenu `
            -Title "Diagnostics" `
            -Options $Menu



    if (
        $Choice -eq "Exit" -or
        $Choice -eq "7"
    ) {

        break

    }



    switch ($Choice) {


        "1" {

            Show-DiagnosticsDashboard

        }


        "2" {

            Show-DiagnosticsHardware

        }


        "3" {

            Invoke-DiagnosticsWindowsHealth

        }


        "4" {

            Show-DiagnosticsEvents

        }


        "5" {

            Show-DiagnosticsNetwork

        }


        "6" {

            Invoke-DiagnosticsReportExport

        }


    }

}

}

#endregion

#region Advanced Network Diagnostics


function Get-ToolkitNetworkAdapters {

    [CmdletBinding()]

    param()


    Get-NetAdapter |
    Where-Object {

        $_.Status -eq "Up"

    } |
    Select-Object `
        Name,
        InterfaceDescription,
        LinkSpeed,
        MacAddress

}



function Get-ToolkitNetworkConfiguration {

    [CmdletBinding()]

    param()



    Get-NetIPConfiguration |
    Where-Object {

        $_.IPv4DefaultGateway

    } |
    Select-Object `
        InterfaceAlias,
        IPv4Address,
        IPv4DefaultGateway,
        DNSServer

}



function Test-ToolkitDNSResolution {

    [CmdletBinding()]

    param()



    try {

        Resolve-DnsName `
            microsoft.com `
            -ErrorAction Stop |
        Out-Null


        return $true

    }

    catch {

        return $false

    }

}



function Test-ToolkitGateway {

    [CmdletBinding()]

    param()



    $Gateway =
        Get-NetRoute `
            -DestinationPrefix "0.0.0.0/0" |
        Sort-Object RouteMetric |
        Select-Object -First 1



    if ($Gateway) {

        return $true

    }


    return $false

}



function Get-ToolkitNetworkLatency {

    [CmdletBinding()]

    param()



    $Hosts = @(
        "1.1.1.1",
        "8.8.8.8",
        "github.com"
    )



    foreach ($HostName in $Hosts) {


        $Ping =
            Test-Connection `
                $HostName `
                -Count 1 `
                -ErrorAction SilentlyContinue



        [PSCustomObject]@{

            Host =
                $HostName

            Latency =
                if ($Ping) {
                    "$($Ping.Latency) ms"
                }
                else {
                    "Failed"
                }

        }

    }

}



function Get-ToolkitAdvancedNetworkStatus {

    [CmdletBinding()]

    param()



    $Internet =
        Test-ToolkitInternetConnection


    $DNS =
        Test-ToolkitDNSResolution


    $Gateway =
        Test-ToolkitGateway


    $VPN =
        Get-ToolkitVPNStatus



    [PSCustomObject]@{

        Internet =
            $Internet

        DNS =
            $DNS

        Gateway =
            $Gateway

        VPN =
            $VPN

        Adapter =
            Get-ToolkitNetworkAdapters

        Configuration =
            Get-ToolkitNetworkConfiguration

        Latency =
            Get-ToolkitNetworkLatency

    }

}


#endregion

Export-ModuleMember `
-Function *
```
