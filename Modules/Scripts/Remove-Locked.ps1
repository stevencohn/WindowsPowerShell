<#
.SYNOPSIS
Remove a System-owned file or directory or a directory containing
a path that is too long.

.PARAMETER name
The path of the file or directory to remove.

.DESCRIPTION
For file and directories, the first attempt is to take ownership
of all objects, change ACL (access control lists) and then delete.

Additionally, for directories, will use "robocopy empty" method 
of overwriting directory containing gratuitously long paths.
#>

param ([string] $name)

if (!(Test-Elevated (Split-Path -Leaf $PSCommandPath) -warn)) { return }


if ((Get-Item $name) -is [System.IO.DirectoryInfo])
{
	try
	{
		# /F<name>==path-to-object /R==recurse /A==grant-admins /D:Y=default-prompt-answer
		takeown /F $name /R /A /D Y
		# /T==recurse /Q==supress-messages
		icacls $name /grant administrators:f /t /q
		Remove-Item $name -Force -Confirm:$false -Recurse
	}
	catch
	{
		Write-Host 'Error taking ownership, trying robocopy method...'
		$empty = "${env:TEMP}\emptydir"
		New-Item $empty -Force -Confirm:$false
		robocopy $empty $name /purge
		Remove-Item $empty -Force -Confirm:$false

		if (Test-Path $name)
		{
			Remove-Item $name -Force -Confirm:$false
		}
	}
}
else
{
	# /F<name>==path-to-object /A==grant-admins
	takeown /F $name /A
	# /Q==supress-messages
	icacls $name /grant administrators:f /q
	Remove-Item $name -Force -Confirm:$false
}
