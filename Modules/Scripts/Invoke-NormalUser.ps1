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

if ($env:ConEmuPID)
{
	# trying to run this in a new tab but it opens a new PowerShell console! :-(
	runas /trustlist:0x20000 $Command
}
else
{
	runas /trustlist:0x20000 $Command
}
