<#
.SYNOPSIS
TrayDevil.exe sometimes disappears from the Windows System Tray.
This simply kills the running process and restarts it so the
icon appears again.

.DESCRIPTION
I set TrayDevil to show the currently day number in the tray icon
so I like the icon to be visible.
#>

$0 = 'C:\Program Files (x86)\TrayDevil\traydevil.exe'
if (Test-Path $0)
{
	Stop-Process -Name 'traydevil' -Force -ErrorAction 'SilentlyContinue'
	& $0
}

