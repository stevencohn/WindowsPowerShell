<#
.synopsis
Remove a System-owned file or directory.

.parameter name
The path of the file or directory to remove.
#>

param ([string] $name)

if (!(Confirm-Elevated (Split-Path -Leaf $PSCommandPath) $true)) { return }


if ((Get-Item $name) -is [System.IO.DirectoryInfo])
{
	# /F<name>==path-to-object /R==recurse /A==grant-admins /D:Y=default-prompt-answer
	takeown /F $name /R /A /D Y
	# /T==recurse /Q==supress-messages
	icacls $name /grant administrators:f /t /q
	Remove-Item $name -Force -Confirm:$false -Recurse
}
else
{
	# /F<name>==path-to-object /A==grant-admins
	takeown /F $name /A
	# /Q==supress-messages
	icacls $name /grant administrators:f /q
	Remove-Item $name -Force -Confirm:$false
}
