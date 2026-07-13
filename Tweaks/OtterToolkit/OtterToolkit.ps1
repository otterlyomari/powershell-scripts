#Requires -Version 7.0
#Requires -RunAsAdministrator

$ModulePath =
    Join-Path `
        $PSScriptRoot `
        "Modules"


Get-ChildItem `
    $ModulePath `
    -Filter "*.psm1" |
ForEach-Object {

    Import-Module `
        $_.FullName `
        -Force

}



Confirm-ToolkitEnvironment

Start-ToolkitSession

Write-Host ""
Write-Host "================================="
Write-Host "        Windows Toolkit"
Write-Host "================================="
Write-Host ""

Write-Host "Windows:"
Get-WindowsVersion |
Format-Table


Write-Host ""
Write-Host "Toolkit loaded successfully."

Pause

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



    if ($Selection -eq "Exit") {

        Write-ToolkitInfo `
            "Toolkit closed."

        break
    }



    switch ($Selection) {


        "1" {

            Write-Host "Tweaks module not loaded yet."
            Pause

        }


"2" {


    while ($true) {


        $AppMenu = @{

            "1" = "Recommended Applications"

            "2" = "Install Application"

            "3" = "Available Package Managers"

            "4" = "Back"

        }



        $Choice =
            Show-ToolkitMenu `
                -Title "Applications" `
                -Options $AppMenu



        if ($Choice -eq "Exit" -or $Choice -eq "4") {

            break

        }



        switch ($Choice) {


            "1" {


                Write-Host ""

                Write-Host "Recommended Applications:"
                Write-Host ""


                Get-ToolkitApplications |
                Format-Table `
                    Name,
                    Category,
                    Id `
                    -AutoSize



                Pause

            }



            "2" {


                        Write-Host ""

                        $Provider =
                            Read-Host `
                            "Package manager (Winget/Scoop)"


                        $Id =
                            Read-Host `
                            "Application ID"



                        Install-ToolkitApplication `
                            -Id $Id `
                            -Provider $Provider



                        Pause

                    }



                    "3" {


                        Write-Host ""

                        Write-Host "Available package managers:"
                        Write-Host ""


                        $Managers =
                            Get-ToolkitPackageManagers



                        if ($Managers.Count -eq 0) {


                            Write-Warning `
                                "No supported package managers found."


                        }

                        else {


                            foreach ($Manager in $Managers) {

                                Write-Host "- $Manager"

                            }

                        }



                        Pause

                    }


                }

            }


        }


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



                if ($Choice -eq "Exit" -or $Choice -eq "4") {

                    break

                }



                switch ($Choice) {


                    "1" {

                        Get-ToolkitComponents |
                        Format-Table


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


        "4" {

            Write-Host "Diagnostics module not loaded yet."
            Pause

        }


        "5" {

            Write-Host "Settings module not loaded yet."
            Pause

        }

    }

}
