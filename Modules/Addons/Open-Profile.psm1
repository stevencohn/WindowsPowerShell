<#
.SYNOPSIS
Open the ISE profile definition script.
#>

function Open-Profile ()
{
    $shell = 'PowerShell'
    if ($PSVersionTable.PSVersion.Major -lt 6) { $shell = 'WindowsPowerShell' }

    $path = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) `
        "shell\Microsoft.PowerShellISE_profile.ps1"

    if (!(Test-Path($path)))
    {
        New-Item $path -ItemType file -Force | Out-Null
    }

    $psISE.CurrentPowerShellTab.Files.Add($path) | Out-Null
}
