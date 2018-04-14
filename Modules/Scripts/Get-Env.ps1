<#
.SYNOPSIS
Print environment variables or special folders.

.PARAMETER highlight
A string specifying text to highlight in the output. Only "Names" are matched.

.PARAMETER special
Switch to display special folders instead of environment variables.
#>

param ([string] $highlight, [switch] $special)

Write-Host ("{0,-30} {1}" -f 'Name', 'Value')
Write-Host ("{0,-30} {1}" -f '----', '-----')

if ($special)
{
	$folders = @{}
	[Enum]::GetValues('System.Environment+SpecialFolder') | % `
	{
		if (!($folders.ContainsKey($_.ToString())))
		{
			$folders.Add($_.ToString(), [Environment]::GetFolderPath($_))
		}
	}

	$pairs = $folders.GetEnumerator() | sort name
}
else
{
	$pairs = Get-ChildItem env: | sort name
}

$pairs | % `
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
	else
	{
		Write-Host ("{0,-30} {1}" -f $name, $value)
	}
}
