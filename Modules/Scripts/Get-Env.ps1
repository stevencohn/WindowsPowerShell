param ([string] $highlight)

Write-Host ("{0,-30} {1}" -f 'Name', 'Value')
Write-Host ("{0,-30} {1}" -f '----', '-----')

Get-ChildItem env: | sort name | % `
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