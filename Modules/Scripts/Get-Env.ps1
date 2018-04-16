<#
.SYNOPSIS
Print environment variables with optional highlighting.

.PARAMETER highlight
An optional string specifying text to highlight in the output. Only "Names" are matched.
#>

param ([string] $highlight)

Write-Host ("{0,-30} {1}" -f 'Name', 'Value')
Write-Host ("{0,-30} {1}" -f '----', '-----')

$pairs = Get-ChildItem env: | sort name | % `
{
	$name = $_.Name.ToString()
	if ($name.Length -gt 30) { $name = $name.Substring(0,27) + '...' }

	$value = $_.Value.ToString()
	$max = $host.UI.RawUI.WindowSize.Width - 32
	if ($value.Length -gt $max) { $value = $value.Substring(0, $max - 3) + '...' }

	if ($highlight -and ($_.Name -match $highlight))
	{
		Write-Host ("{0,-30} {1}" -f $name, $value) -ForegroundColor Green
	}
	elseif ([String]::IsNullOrEmpty($highlight))
	{
		if ($_.Name -eq 'ProgramData')
		{
			Write-Host ("{0,-30} {1}" -f $name, $value) -ForegroundColor Blue				
		}
		elseif ($_.Name -match 'APPDATA')
		{
			Write-Host ("{0,-30} {1}" -f $name, $value) -ForegroundColor Magenta
		}
		elseif ($value -match "$env:USERNAME(?:\\\w+){0,1}$")
		{
			Write-Host ("{0,-30} {1}" -f $name, $value) -ForegroundColor DarkGreen
		}
		else
		{
			Write-Host ("{0,-30} {1}" -f $name, $value)
		}
	}
	else
	{
		Write-Host ("{0,-30} {1}" -f $name, $value)
	}
}
