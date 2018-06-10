<#
.SYNOPSIS
Clear all events from the Windows Event Log.

.PARAMETER Quiet
If specified then supress output. Default is to show a dot for each log cleared
#>

param([switch] $quiet)

$count = 0
$size = 0
$skip = 0

# Here we use Get-WinEvent instead of 'wevtutil el'. While this is slow, we can control
# the error messages using ErrorAction, whereas wevtutil spits out errors regardless!
# Get-WinEvent also returns meta information about each log like RecordCount and FileSize.

(Get-WinEvent -Listlog * -Force -ErrorAction SilentlyContinue) | % `
{
	if ($_.RecordCount -gt 0)
	{
		if (!$quiet) { Write-Host '.' -NoNewline }
		$name = $_.LogName
		try
		{
			# Here we use the .NET API directly rather than 'wevtutil 'cl'. Just as fast.

			$size += $_.FileSize
			[System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($name)
			$count++
		}
		catch
		{
			$skip++
		}
	}
}

if (!$quiet)
{
	[double] $kb = $size / 1024
	Write-Host "`n"
	Write-Host("Cleared {0} logs saving {1} KB" -f $count, $kb) -Foreground DarkYellow

	if ($skip -gt 0)
	{
		Write-Host("Skipped {0} logs" -f $skip) -Foreground DarkYellow
	}
}
