<#
.SYNOPSIS
Get and search the full history command line history.

.PARAMETER Arg1
Interchangeable with Arg2, specifies either the number of most recent items to
return or a string used to search the history.

.PARAMETER Arg2
Interchangeable with Arg1, specifies either the number of most recent items to
return or a string used to search the history.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	$arg1 = $null,
	$arg2 = $null
)

Begin
{
	$script:id = 1

	function MeasureHistory
	{
		# counts all lines so we can adjust the offset when only tailing
		$count = (Get-Content $savePath | Measure-Object).Count
		$script:id = $count - $last + 1
	}

	function GetHistory
	{
		if ($last -gt 0 -and $match -ne $null)
		{
			Get-Content -Last $last $savePath | where { $_ -like "*$match*" } | foreach { FormatLine $_ } | more
		}
		elseif ($last -gt 0)
		{
			Get-Content -Last $last $savePath | foreach { FormatLine $_ } | more
		}
		elseif ($match -ne $null)
		{
			Get-Content $savePath | where { $_ -like "*$match*" } | foreach { FormatLine $_ } | more
		}
		else
		{
			Get-Content $savePath | foreach { FormatLine $_ } | more
		}
	}

	function FormatLine
	{
		param([Parameter(Mandatory = $true, ValueFromPipeline=$true)] $line)
		$s = (' {0,4}    {1}' -f $id,$line)
		$script:id++
		return $s
	}
}
Process
{
	$script:last = 40
	$script:match = $null

	# because I'm too lazy to remember param names...

	if ($arg1)
	{
		$typnam = $arg1.GetType().Name
		if ($typnam -eq 'String') { $script:match = $arg1 }
		elseif ($typnam -like 'Int*') { $script:last = $arg1 }
	}

	if ($arg2)
	{
		$typnam = $arg2.GetType().Name
		if ($typnam -eq 'String') { $script:match = $arg2 }
		elseif ($typnam -like 'Int*') { $script:last = $arg2 }
	}

	$script:savePath = (Get-PSReadlineOption).HistorySavePath

	MeasureHistory
	GetHistory
}
