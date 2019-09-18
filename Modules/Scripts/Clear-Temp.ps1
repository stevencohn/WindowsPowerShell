<#
.SYNOPSIS
Clear the contents of TEMP, Windows\TEMP, and LocalAppData\TEMP.

.PARAMETER Quiet
Suppress any output; default is to report amount of disk space recovered.
#>

param([switch] $Quiet)


$used = (Get-PSDrive C).Used
$filCount = 0
$dirCount = 0

$0 = 'C:\Temp'
if (Test-Path $0)
{
	$fils = [System.IO.Directory]::GetFiles($0, '*').Count
	$dirs = [System.IO.Directory]::GetDirectories($0, '*').Count

	Remove-Item -Path $0 -Force -Recurse -ErrorAction:SilentlyContinue

	$fc = $fils - [System.IO.Directory]::GetFiles($0, '*').Count
	$dc = $dirs - [System.IO.Directory]::GetDirectories($0, '*').Count

	$filCount += $fc
	$dirCount += $dc

	if (!$Quiet)
	{
		Write-Host "... removed $fc files, $dc directories from $0" -ForegroundColor DarkGray
	}
}

$0 = 'C:\Windows\Temp'
if (Test-Path $0)
{
	$fils = [System.IO.Directory]::GetFiles($0, '*').Count
	$dirs = [System.IO.Directory]::GetDirectories($0, '*').Count

	Remove-Item -Path $0 -Force -Recurse -ErrorAction:SilentlyContinue

	$fc = $fils - [System.IO.Directory]::GetFiles($0, '*').Count
	$dc = $dirs - [System.IO.Directory]::GetDirectories($0, '*').Count

	$filCount += $fc
	$dirCount += $dc

	if (!$Quiet)
	{
		Write-Host "... removed $fc files, $dc directories from $0" -ForegroundColor DarkGray
	}
}

$0 = Join-Path $env:LocalAppData 'Temp'
if (Test-Path $0)
{
	$fils = [System.IO.Directory]::GetFiles($0, '*').Count
	$dirs = [System.IO.Directory]::GetDirectories($0, '*').Count

	Remove-Item -Path "$0\*" -Force -Recurse -ErrorAction:SilentlyContinue

	$fc = $fils - [System.IO.Directory]::GetFiles($0, '*').Count
	$dc = $dirs - [System.IO.Directory]::GetDirectories($0, '*').Count

	$filCount += $fc
	$dirCount += $dc

	if (!$Quiet)
	{
		Write-Host "... removed $fc files, $dc directories from $0" -ForegroundColor DarkGray
	}
}

if (!$Quiet)
{
	$disk = Get-PSDrive C | Select-Object Used,Free
	$pct = ($disk.Used / ($disk.Used + $disk.Free)) * 100
	$recovered = $used - $disk.Used
	Write-Host "... removed $filCount files, $dirCount directories"
	Write-Host ("... recovered {0:0.00} MB on drive C, {1:0.00}% used" -f ($recovered / 1024000), $pct)
}
