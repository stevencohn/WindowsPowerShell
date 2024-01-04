
# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	$arg1 = $null,
	$arg2 = $null
)

Begin
{
	$script:id = 1

	function GetHistory
	{
		if ($last -gt 0 -and $match -ne $null)
		{
			Get-Content -Last $last $hxPath | where { $_ -like "*$match*" } | foreach { FormatLine $_ } | more
		}
		elseif ($last -gt 0)
		{
			Get-Content -Last $last $hxPath | foreach { FormatLine $_ } | more
		}
		elseif ($match -ne $null)
		{
			Get-Content $hxPath | where { $_ -like "*$match*" } | foreach { FormatLine $_ } | more
		}
		else
		{
			Get-Content $hxPath | foreach { FormatLine $_ } | more
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
	$script:last = 0
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

	$hxPath = (Get-PSReadlineOption).HistorySavePath
	Write-Host $hxPath -ForegroundColor Green
	Write-Host
	Write-Host '   Id    CommandLine'
	Write-Host '   --    -----------'

	GetHistory
}
