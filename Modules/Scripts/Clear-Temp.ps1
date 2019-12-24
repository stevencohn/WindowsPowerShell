<#
.SYNOPSIS
Clear the contents of TEMP, Windows\TEMP, and LocalAppData\TEMP.

.PARAMETER Quiet
Suppress any output; default is to report amount of disk space recovered.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param([switch] $Quiet)

Begin
{
	function ClearFolder
	{
		param($path)

		if (!(Test-Path $path)) { return }

		$fils = [System.IO.Directory]::GetFiles($path, '*').Count
		$dirs = [System.IO.Directory]::GetDirectories($path, '*').Count

		Write-Verbose "... clearing $path"
		Remove-Item -Path "$path\*" -Force -Recurse -ErrorAction:SilentlyContinue

		$fc = $fils - [System.IO.Directory]::GetFiles($path, '*').Count
		$dc = $dirs - [System.IO.Directory]::GetDirectories($path, '*').Count

		$script:filCount += $fc
		$script:dirCount += $dc

		if (!$Quiet)
		{
			Write-Host "... removed $fc files, $dc directories from $path" -ForegroundColor DarkGray
		}
	}
}
Process
{
	$used = (Get-PSDrive C).Used
	$script:filCount = 0
	$script:dirCount = 0

	ClearFolder 'C:\Temp'
	ClearFolder 'C:\Tmp'
	ClearFolder 'C:\Windows\Temp'
	ClearFolder (Join-Path $env:LocalAppData 'Temp')

	if (!$Quiet)
	{
		$disk = Get-PSDrive C | Select-Object Used,Free
		$pct = ($disk.Used / ($disk.Used + $disk.Free)) * 100
		$recovered = $used - $disk.Used
		Write-Host "... removed $filCount files, $dirCount directories"
		Write-Host ("... recovered {0:0.00} MB on drive C, {1:0.00}% used" -f ($recovered / 1024000), $pct)
	}
}
