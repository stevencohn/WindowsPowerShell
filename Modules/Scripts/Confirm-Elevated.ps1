
<#
.SYNOPSIS
Display an warning message if the current command prompt session does not have elevated permissions.
.DESCRIPTION
For scripts in this same \Scripts folder, add these two lines exactly:

$confirm = [IO.Path]::Combine((Split-Path -parent $PSCommandPath), 'Confirm-Elevated.ps1')
if (!(. $confirm (Split-Path -Leaf $PSCommandPath) $true)) { return }

For scripts in other locations, just call Confirm-Elevated [action-name] [show-warning]
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
