
Write-Host "`nSystem.ConsoleColor :: HKCU:\Console :: -ForegroundColor`n"
Push-Location HKCU:\Console

$colors = [System.Enum]::GetNames([System.ConsoleColor])

For ($i=0; $i -lt $colors.Length; $i++) `
{
	$table = ("ColorTable{0}" -f ($i).ToString('00'))
	$value = (Get-ItemPropertyValue . -name $table)

	$basics = "{0} {1} {2}" -f $table, $value.ToString('X8'), $colors[$i]
	$decimal = "{0}, {1}, {2}" -f ($value -band 0xff), (($value -band 0xff00) -shr 8), (($value -band 0xff0000) -shr 16)

	if ($colors[$i] -eq 'Black') {
		Write-Host ("{0,-35} {1}" -f $basics, $decimal) -ForegroundColor $colors[$i] -BackgroundColor DarkGray	
	}
	else {
		Write-Host ("{0,-35} {1}" -f $basics, $decimal) -ForegroundColor $colors[$i]
	}
}

Pop-Location
