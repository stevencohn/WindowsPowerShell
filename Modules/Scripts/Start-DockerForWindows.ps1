<#
.SYNOPSIS
Start the Docker Desktop application if it is not already running
or bring the window to the front if it is running (To do). 
If Docker for Windows is installed instead then that is started.
#>

$0 = 'C:\Program Files\Docker\Docker'

if (Test-Path "$0\Docker Desktop.exe")
{
	& "$0\Docker Desktop.exe"
}
else
{
	& "$0\Docker for Windows.exe"
}
