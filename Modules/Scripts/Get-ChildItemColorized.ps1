<#
.SYNOPSIS
Display the current directory listing with total size.
#>
param (
	$dir,
	[System.Management.Automation.SwitchParameter] $la)
	
Get-Childitem $dir -force:$la
Get-DirSize $dir -la:$la

