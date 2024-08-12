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

<#
https://superuser.com/questions/1749696/parameter-is-incorrect-when-using-runas-with-trustlevel-after-windows-11-22h2

The workaround with /machine:x86|amd64|arm|arm64 works. If you are on a 64bit intel machine and
want to execute a batchfile there is no machine option that will work since cmd.exe is a 64 bit
application. There is a 32bit version for cmd.exe at C:\Windows\sysWOW64\cmd.exe, so a command
could be as follows:

runas /machine:x86 /trustlevel:0x20000 "C:\Windows\sysWOW64\cmd.exe <yourBatchfileHere>"
#>

runas /machine:x86 /trustlevel:0x20000 "C:\Windows\sysWOW64\cmd.exe /c `"$Command`""
