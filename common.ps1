<#
Library of common functions shared by the Install-foo scripts.
#>

$proEdition = $null


function Chocolatize
{
    param($name)
    if (UnChocolatized $name)
    {
        HighTitle $name
        choco install -y $name
    }
    else
    {
        WriteOK "$name already installed by chocolatey"
    }
}

function Chocolatized
{
    param($name)
    ((choco list -l $name | Select-string "$name ").count -gt 0)
}

function UnChocolatized
{
    param($name)
    ((choco list -l $name | Select-string "$name ").count -eq 0)
}

function DownloadBootstrap
{
    # source=filename, target=folder
    param($source, $target)
    $zip = Join-Path $target $source

    if ($false) #$env:GITHUB_TOKEN)
    {
        curl -s -H "Authorization: token $($env:GITHUB_TOKEN)" `
            -H 'Accept: application/vnd.github.v3.raw' `
            -o $zip -L "https://api.github.com/repos/stevencohn/bootstraps/contents/$source`?ref=main"
    }
    else
    {
        curl -s "https://raw.githubusercontent.com/stevencohn/bootstraps/main/$source" -o $zip
    }

    Expand-Archive $zip -DestinationPath $target -Force | Out-Null
    Remove-Item $zip -Force -Confirm:$false
}

function Highlight
{
    param($text = '', $color = 'Yellow')
    $text | Write-Host -ForegroundColor Black -BackgroundColor $color
}

function HighTitle
{
    param($title, $action = 'Installing')
    Highlight '', "---- $action $title ---------------------------"
}

function InstallCurl
{
    if ((Get-Alias curl -ErrorAction:SilentlyContinue) -ne $null) {
        Remove-Item alias:curl -ErrorAction:SilentlyContinue
    }

    $cmd = Get-Command curl -ErrorAction:SilentlyContinue
    if ($cmd -ne $null)
    {
        if ($cmd.Source.Contains('curl.exe')) { return }
    }

    if ((Get-Command choco -ErrorAction:SilentlyContinue) -eq $null)
    {
        HighTitle 'Installing Chocolatey'
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    if ((choco list -l 'curl' | Select-string 'curl ').count -gt 0) { return }

    HighTitle 'Curl'
    choco install -y curl
}

function InstallChocolatey
{
    # Modules/Scripts contains a better version but this is a stand-alone copy for the
    # top-level Install scripts so they can remain independent of the Module scripts
    if ((Get-Command choco -ErrorAction:SilentlyContinue) -eq $null)
    {
        HighTitle 'Chocolatey'
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

function InstallGit
{
    if ((Get-Command git -ErrorAction:SilentlyContinue) -eq $null)
    {
        HighTitle 'Git'
        choco install -y git
        # Git adds its path to the Machine PATH but not the Process PATH; copy it so we don't need to restart the shell
        $gitpath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine) -split ';' | ? { $_ -match 'Git\\cmd' }
        $env:Path = "${env:Path};$gitpath"
    }
}

function IsElevated
{
    # Modules/Scripts contains a better/alt version but this is a stand-alone copy for the
    # top-level Install scripts so they can remain independent of the Module scripts
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()`
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        return $true
    }

    Write-Host
    WriteWarn '... This script must be run from an elevated console'
    WriteWarn '... Open an administrative PowerShell window and run again'
    return $false
}

function IsWindows11
{
    $0 = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    ([int](Get-ItemPropertyValue -path $0 -name CurrentBuild) -ge 22000)
}

function IsWindowsHomeEdition
{
    return (-not (IsWindowsProEdition))
}

function IsWindowsProEdition
{
    if ($null -eq $proEdition)
    {
        $script:proEdition = (Get-WindowsEdition -online).Edition -eq 'Professional'
    }

    $proEdition
}

function WriteOK
{
    param($text)
    $text | Write-Host -ForegroundColor Green
}
function WriteWarn
{
    param($text)
    $text | Write-Host -ForegroundColor Yellow
}