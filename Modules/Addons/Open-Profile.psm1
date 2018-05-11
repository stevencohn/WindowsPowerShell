<#
.SYNOPSIS
Open the ISE profile definition script.
#>

function Open-Profile ()
{
    $path = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) `
        "WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1"

    if (!(Test-Path($path)))
    {
        New-Item $path -ItemType file -Force | Out-Null
    }

    $psISE.CurrentPowerShellTab.Files.Add($path) | Out-Null
}
