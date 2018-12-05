<#
.SYNOPSIS
Display the current directory listing with total size.

.PARAMETER la
Show hidden item if specified. Default is to hide hidden items.
#>

param (
	$dir,
	[System.Management.Automation.SwitchParameter] $la)

# See Set-OutputDefaultOverride.ps1 for implementation...
Get-Childitem $dir -force:$la

Get-DirSize $dir -la:$la

