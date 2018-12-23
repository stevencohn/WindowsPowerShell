<#
.SYNOPSIS
Get a list of services ordered by status and name.

.PARAMETER Name
The name or wildcard to match on the Name property of each service.

.PARAMETER Running
Only show services that are running.

.PARAMETER Stopped
Only show services that are not running.
#>

param (
	[string] $Name = '*',
	[switch] $Running,
	[switch] $Stopped
)

if ($Running)
{
	$services = Get-Service $Name | ? { $_.Status -eq 'Running' }
}
elseif ($Stopped)
{
	$services = Get-Service $Name | ? { $_.Status -ne 'Running' }
}
else
{
	$services = Get-Service $Name
}

$width = $host.UI.RawUI.WindowSize.Width - 46

$services | Sort-Object -Property @{ Expression='status'; Descending=$true }, name | % `
{
	$c = if ($_.Status -eq 'Running'){ 'blue'} else {'darkgray'}

	$sname = $_.Name
	if ($sname.Length -gt 35) { $sname = $sname.Substring(0,35) }
	Write-Host $sname.PadRight(35,' ') -NoNewline -ForegroundColor $c

	Write-Host $_.StartType.ToString().PadRight(10,' ') -NoNewline

	$dname = $_.DisplayName
	if ($dname.Length -gt $width) { $dname = $dname.Substring(0, $width - 3) + '...' }
	Write-Host " $dname"
}
