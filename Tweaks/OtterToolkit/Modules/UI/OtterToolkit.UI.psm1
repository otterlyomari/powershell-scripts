#Requires -Version 7.0

<#
.SYNOPSIS
OtterToolkit terminal UI framework.
#>


#region Display


function Show-ToolkitHeader {

    Clear-Host

    Write-Host ""
    Write-Host "================================="
    Write-Host "          OtterToolkit"
    Write-Host "================================="
    Write-Host ""

}



function Show-ToolkitFooter {

    Write-Host ""
    Write-Host "---------------------------------"
    Write-Host "↑ ↓ Navigate   ENTER Select"
    Write-Host "Q Quit / ESC Back"
    Write-Host ""

}


#endregion



#region Interactive Menu


function Show-ToolkitMenu {


param(

    [Parameter(Mandatory)]
    [string]
    $Title,


    [Parameter(Mandatory)]
    [hashtable]
    $Options

)



$Items =
    $Options.Keys |
    Sort-Object |
    ForEach-Object {

        [PSCustomObject]@{

            Key = $_

            Value =
                $Options[$_]

        }

    }



$Index = 0



while ($true) {


    Show-ToolkitHeader


    Write-Host $Title
    Write-Host ""



    for (
        $i = 0;
        $i -lt $Items.Count;
        $i++
    ) {


        if (
            $i -eq $Index
        ) {


            Write-Host `
                "> $($Items[$i].Value)"


        }

        else {


            Write-Host `
                "  $($Items[$i].Value)"


        }


    }



    Show-ToolkitFooter



    $Key =
        [Console]::ReadKey($true)



    switch (
        $Key.Key
    ) {



        "UpArrow" {


            $Index--


            if (
                $Index -lt 0
            ) {

                $Index =
                    $Items.Count - 1

            }


        }



        "DownArrow" {


            $Index++


            if (
                $Index -ge $Items.Count
            ) {

                $Index = 0

            }


        }



        "Enter" {


            return (
                $Items[$Index].Key
            )


        }



        "Escape" {


            return "Back"


        }



        "Q" {


            return "Exit"


        }


    }


}



}


#endregion



#region Confirmation


function Confirm-ToolkitAction {


param(

    [Parameter(Mandatory)]
    [string]
    $Message

)



Write-Host ""
Write-Host $Message
Write-Host ""



$key =
    [Console]::ReadKey()



return (
    $key.Key -eq "Y"
)


}



#endregion



Export-ModuleMember `
    -Function *