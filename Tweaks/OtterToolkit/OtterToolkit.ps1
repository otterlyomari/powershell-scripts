#Requires -Version 7.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
OtterToolkit main entry point.

.DESCRIPTION
Loads toolkit modules and starts
the interactive CLI interface.
#>


#region Module Loading


$ModulePath =
Join-Path `
    $PSScriptRoot `
    "Modules"



Get-ChildItem `
    $ModulePath `
    -Filter "*.psm1" `
    -Recurse |
Sort-Object FullName |
ForEach-Object {


    Import-Module `
        $_.FullName `
        -Force

}


#endregion



#region Startup


Confirm-ToolkitEnvironment

Start-ToolkitSession



Clear-Host


Write-Host ""
Write-Host "================================="
Write-Host "        OtterToolkit"
Write-Host "================================="
Write-Host ""


Write-Host "Windows:"
Get-WindowsVersion |
Format-Table


Write-Host ""
Write-ToolkitInfo `
    "Toolkit loaded successfully."



Pause



#endregion



#region Main Menu


$MainMenu = @{

    "1" = "Windows Tweaks"

    "2" = "Applications"

    "3" = "Windows Components"

    "4" = "Diagnostics"

    "5" = "Settings"

}



while ($true) {


    $Selection =
        Show-ToolkitMenu `
            -Title "Main Menu" `
            -Options $MainMenu



    if (
        $Selection -eq "Exit"
    ) {

        Write-ToolkitInfo `
            "Toolkit closed."

        # todo: add a 15-25 second delay before calling Clear-Host
        # commented out temporarily until this todo is finished
        #Clear-Host

        break

    }



    switch ($Selection) {


        #----------------------------------
        # Tweaks
        #----------------------------------

        "1" {


            Write-Host ""
            Write-Host "Tweaks module not loaded yet."

            Pause

        }



        #----------------------------------
        # Applications
        #----------------------------------

        "2" {


            Start-ApplicationManager


        }



        #----------------------------------
        # Windows Components
        #----------------------------------

        "3" {


            while ($true) {


                $ComponentMenu = @{

                    "1" = "List Windows Components"

                    "2" = "Enable Component"

                    "3" = "Disable Component"

                    "4" = "Back"

                }



                $Choice =
                    Show-ToolkitMenu `
                        -Title "Windows Components" `
                        -Options $ComponentMenu



                if (
                    $Choice -eq "Exit" -or
                    $Choice -eq "4"
                ) {

                    break

                }



                switch ($Choice) {


                    "1" {


                        Get-ToolkitComponents |
                        Format-Table `
                            Name,
                            State,
                            Provider `
                            -AutoSize



                        Pause

                    }



                    "2" {


                        $Name =
                            Read-Host `
                            "Component name"



                        Enable-ToolkitComponent `
                            -Name $Name



                        Pause

                    }



                    "3" {


                        $Name =
                            Read-Host `
                            "Component name"



                        Disable-ToolkitComponent `
                            -Name $Name



                        Pause

                    }


                }


            }


        }



        #----------------------------------
        # Diagnostics
        #----------------------------------

        "4" {

            Start-DiagnosticsManager

            Pause

        }



        #----------------------------------
        # Settings
        #----------------------------------

        "5" {


            Write-Host ""
            Write-Host "Settings module not loaded yet."

            Pause

        }


    }


}


#endregion