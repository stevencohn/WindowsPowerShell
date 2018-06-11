
<#
.SYNOPSIS
Display an warning message if the current command prompt session does not have elevated permissions.

.PARAMETER Action
A brief description of the action that would be blocked if not elevated

.PARAMETER Warn
If specified then displays a warning message if not elevated

.DESCRIPTION
For scripts in this same \Scripts folder, add these two lines exactly:

$confirm = [IO.Path]::Combine((Split-Path -parent $PSCommandPath), 'Test-Elevated.ps1')
if (!(. $confirm (Split-Path -Leaf $PSCommandPath) -warn)) { return }

For scripts in other locations, just call Test-Elevated [action-name] [show-warning]
#>
param (
	[string] $Action = $null,
	[switch] $Warn)

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()`
).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($Warn -and !$isElevated -and ($action -ne $null))
{
	Write-Host
	Write-Host ... `'$Action`' requires administrative permission -ForegroundColor Yellow
	Write-Host("    try rerunning from an administrative command prompt") -ForegroundColor Yellow
	Write-Host
}

return $isElevated
