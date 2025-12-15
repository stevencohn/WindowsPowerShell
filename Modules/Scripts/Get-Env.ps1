<#
.SYNOPSIS
Print environment variables with optional highlighting.

.PARAMETER Edit


.PARAMETER Name
A string used to match and highlight entries based on their name.

.PARAMETER Only
Only display matched entries.

.PARAMETER Value
A string used to match and highlight entries based on their value.
#>

param (
	[string] $Name,
	[string] $Value,
	[switch] $Only,
	[switch] $Edit)

if ($Edit)
{
	Start-Process rundll32 -ArgumentList 'sysdm.cpl,EditEnvironmentVariables'
	return
}

$format = '{0,-30} {1}'

Write-Host ($format -f 'Name', 'Value')
Write-Host ($format -f '----', '-----')

Get-ChildItem env: | sort name | % `
{
	$ename = $_.Name.ToString()
	if ($ename.Length -gt 30) { $ename = $ename.Substring(0,27) + '...' }

	$evalue = $_.Value.ToString()
	$max = $host.UI.RawUI.WindowSize.Width - 32
	if ($evalue.Length -gt $max) { $evalue = $evalue.Substring(0, $max - 3) + '...' }

	if ($Name -and ($_.Name -match $Name))
	{
		Write-Host ($format -f $ename, $evalue) -ForegroundColor Green
	}
	elseif ($Value -and ($_.Value -match $Value) -and !$Only)
	{
		Write-Host ($format -f $ename, $evalue) -ForegroundColor DarkGreen
	}
	elseif ([String]::IsNullOrEmpty($Name) -and [String]::IsNullOrEmpty($Value) -and !$Only)
	{
		if ($_.Name -eq 'COMPUTERNAME' -or $_.Name -eq 'USERDOMAIN')
		{
			Write-Host ($format -f $ename, $evalue) -ForegroundColor Blue
		}
		elseif ($_.Name -match 'APPDATA' -or $_.Name -eq 'ProgramData')
		{
			Write-Host ($format -f $ename, $evalue) -ForegroundColor Magenta
		}
		elseif ($evalue -match "$env:USERNAME(?:\\\w+){0,1}$")
		{
			Write-Host ($format -f $ename, $evalue) -ForegroundColor DarkGreen
		}
		elseif ($_.Name -match 'AWS_')
		{
			Write-Host ($format -f $ename, $evalue) -ForegroundColor DarkYellow
		}
		elseif ($_.Name -match 'ConEmu' -or $_.Value.IndexOf('\') -lt 0)
		{
			Write-Host ($format -f $ename, $evalue) -ForegroundColor DarkGray
		}
		else
		{
			Write-Host ($format -f $ename, $evalue)
		}
	}
	elseif (!$Only)
	{
		Write-Host ($format -f $ename, $evalue)
	}
}
