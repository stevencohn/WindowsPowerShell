<#
.SYNOPSIS
Get performance metrics using the WinSAT utility.
#>

using assembly System.Xml.Linq 
using namespace System.Xml.Linq 

if (-not (Get-Command 'winsat' -ErrorAction:Ignore))
{
	throw 'WinSAT is not installed on this system'
}

if (!(Test-Elevated (Split-Path -Leaf $PSCommandPath) -warn)) { return }

$storepath = Join-Path $env:windir 'Performance\WinSAT\DataStore'
if (!(Test-Path $storepath))
{
	New-Item $storepath -ItemType Directory -Force
}

Write-Host "`nGathering Statistics..." -ForegroundColor Yellow
winsat formal

$file = (Get-Item "${storepath}\*formal*.xml" | Sort-Object -Descending -Property CreationTime | Select-Object -First 1).FullName

Write-Host "`nReformating result file" -ForegroundColor Yellow
[XElement]::Load($file).Save($file, [SaveOptions]::None)

Write-Host "`nReporting from ${file}" -ForegroundColor Yellow
$xml = [xml](Get-Content -Path $file)

# show just WinSPR node from XML
$xml.WinSAT.WinSPR
