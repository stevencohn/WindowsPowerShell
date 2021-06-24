<#
.SYNOPSIS
Reports all processes with Id, Name, and CommandLine and highlights categories of and
optional specified processes.

.PARAMETER Name
A string used to match and highlight entries based on their name.

.PARAMETER Only
Only display matched entries.

.PARAMETER ReturnValue
A switch, if specified as $true, returns the commandline of the specified process rather
than generating a report

.PARAMETER ShowSystem
Show processes running out of Windows\System32 folder; default is to hide these processes
#>

param (
	[string] $Name,
	[switch] $ShowSystem,
	[switch] $Only,
	[switch] $ReturnValue)

if (!$Name)
{
	$Only = $false
	$ReturnValue = $false
}

$format = '{0,10} {1,-33} {2}'

if (!$ReturnValue)
{
	Write-Host ($format -f 'processid', 'ProcessName', 'CommandLine')
	Write-Host ($format -f '---------', '-----------', '-----------')
}

gcim Win32_Process | sort -Property ProcessName | select ProcessId, ProcessName, CommandLine | % `
{
	$procnam = [IO.Path]::GetFileNameWithoutExtension($_.ProcessName)
	if ($procnam.Length -gt 33) { $procnam = $procnam.Substring(0,31) + '...' }

	$commandLine = $_.CommandLine
	if (!$commandLine) { $commandLine = '' }
	$cmd = $commandLine
	$max = $host.UI.RawUI.WindowSize.Width - 45
	if ($cmd.Length -gt $max) { $cmd = $cmd.Substring(0, $max - 3) + '...' }

	if ($Name -and ($procnam -like "*$Name*" -or $commandLine -like "*$Name*"))
	{
		if ($ReturnValue) { return $_.CommandLine }

		Write-Host ($format -f $_.ProcessId, $procnam, $cmd) -ForegroundColor Green
		if ($Only) { return }
	}
	elseif (!$Only -and !$ReturnValue)
	{
		if ($cmd -and ($cmd -like "*$($env:windir)\System32*"))
		{
			if ($ShowSystem)
			{
				Write-Host ($format -f $_.ProcessId, $procnam, $cmd) -ForegroundColor DarkGray
			}
		}
		else
		{
			Write-Host ($format -f $_.ProcessId, $procnam, $cmd)
		}
	}
}
