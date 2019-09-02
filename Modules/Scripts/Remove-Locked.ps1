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


Set-ItemOwner $name

if ((Get-Item $name) -is [System.IO.DirectoryInfo])
{
	Remove-Item $name -Force -Confirm:$false -Recurse
}
else
{
	Remove-Item $name -Force -Confirm:$false
}
