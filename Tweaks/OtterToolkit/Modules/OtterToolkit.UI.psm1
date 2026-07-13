#Requires -Version 7.0

<#
.SYNOPSIS
Terminal user interface for WindowsToolkit.

.DESCRIPTION
Provides reusable menu components.
#>


#region Display


function Show-ToolkitHeader {

    Clear-Host


    Write-Host ""
    Write-Host "================================="
    Write-Host "        Windows Toolkit"
    Write-Host "================================="
    Write-Host ""

}



function Show-ToolkitFooter {

    Write-Host ""
    Write-Host "---------------------------------"
    Write-Host "Q. Quit"
    Write-Host ""

}


#endregion



#region Menu System


function Show-ToolkitMenu {

    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [hashtable]$Options
    )


    while ($true) {

        Show-ToolkitHeader


        Write-Host $Title
        Write-Host ""


        foreach ($Key in $Options.Keys | Sort-Object) {

            Write-Host "[$Key] $($Options[$Key])"

        }


        Show-ToolkitFooter


        $Choice =
            Read-Host "Select an option"



        if ($Choice -eq "q") {

            return "Exit"

        }


        if ($Options.ContainsKey($Choice)) {

            return $Choice

        }


        Write-Host ""
        Write-Warning "Invalid selection."

        Start-Sleep -Seconds 2
    }

}


#endregion



#region Confirmations


function Confirm-ToolkitAction {

    param(
        [Parameter(Mandatory)]
        [string]$Message
    )


    Write-Host ""
    Write-Host $Message
    Write-Host ""


    $Response =
        Read-Host "[Y/N]"


    return (
        $Response -eq "Y" -or
        $Response -eq "y"
    )

}


#endregion



Export-ModuleMember -Function *