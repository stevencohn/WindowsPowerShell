<#
.SYNOPSIS
Start the given command as a non-elevated process from the currently
elevated process. This also works from a non-elevated context.

.PARAMETER Command
The command to execute as a non-elevated process.
#>

param (
	[Parameter(Mandatory=$true)]
	[string] $Command
	)

#https://superuser.com/questions/1749696/parameter-is-incorrect-when-using-runas-with-trustlevel-after-windows-11-22h2
runas /machine:x86 /trustlevel:0x20000 "C:\Windows\sysWOW64\cmd.exe /c `"$Command`""
