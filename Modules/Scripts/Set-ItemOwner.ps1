<#
.SYNOPSIS
Set the ownership of an item - folder or file - to the specified user group
or user.

.PARAMETER Path
The path of the file or directory.

.PARAMETER Group
The name of the user group to allow.
#>

param (
	[string] $Path,
	[string] $Group = 'administrators'
	)

if (!(Test-Elevated (Split-Path -Leaf $PSCommandPath) -warn)) { return }

if ((Get-Item $Path) -is [System.IO.DirectoryInfo])
{
	try
	{
		# /F<name>==path-to-object /R==recurse /A==grant-admins /D:Y=default-prompt-answer
		takeown /F $Path /R /A /D Y
		# /T==recurse /Q==supress-messages
		icacls $Path /grant $Group`:f /t /q
	}
	catch
	{
		Write-Host 'Error taking ownership, trying robocopy method...'
		$empty = "${env:TEMP}\emptydir"
		New-Item $empty -Force -Confirm:$false
		robocopy $empty $Path /purge
		Remove-Item $empty -Force -Confirm:$false
	}
}
else
{
	# /F<name>==path-to-object /A==grant-admins
	takeown /F $Path /A
	# /Q==supress-messages
	icacls $Path /grant $Group`:f /q
}
