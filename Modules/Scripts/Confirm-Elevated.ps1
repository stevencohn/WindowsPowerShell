
<#
.SYNOPSIS
Display an warning message if the current command prompt session does not have elevated permissions.
#>
param (
	[string] $action = $null,
	[bool] $warn = $false)

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()`
).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($warn -and !$isElevated -and ($action -ne $null))
{
	Write-Host
	Write-Host ... `'$action`' requires administrative permission -ForegroundColor Yellow
	Write-Host("    try rerunning from an administrative command prompt") -ForegroundColor Yellow
	Write-Host
}

return $isElevated
