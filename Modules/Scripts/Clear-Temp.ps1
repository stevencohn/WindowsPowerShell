<#
.SYNOPSIS
Clear the contents of TEMP, Windows\TEMP, and LocalAppData\TEMP.

.PARAMETER Quiet
Suppress any output; default is to report amount of disk space recovered.
#>

param([switch] $Quiet)


$used = (Get-PSDrive C).Used

if (Test-Path 'C:\Temp')
{
	Remove-Item -Path 'C:\Temp' -Force -Recurse -ErrorAction:SilentlyContinue
}

if (Test-Path 'C:\Windows\Temp')
{
	Remove-Item -Path 'C:\Windows\Temp' -Force -Recurse -ErrorAction:SilentlyContinue
}

$t = Join-Path $env:LocalAppData 'Temp'
if (Test-Path $t)
{
	Remove-Item -Path "$t\*" -Force -Recurse -ErrorAction:SilentlyContinue
}

if (!$Quiet)
{
	$disk = Get-PSDrive C | Select-Object Used,Free
	$pct = ($disk.Used / ($disk.Used + $disk.Free)) * 100
	$recovered = $used - $disk.Used
	Write-Host ("... recovered {0:0.00} MB on drive C, {1:0.00}% used" -f ($recovered / 1024000), $pct)
}
