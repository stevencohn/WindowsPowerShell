<#
.SYNOPSIS
Display the console colors as defined in the Registry.

.DESCRIPTION
Registry values are stored as B-G-R DWord values. This command displays the BGR
value as well as the RGB and decimal equivalents.
#>

$esc = [char]27
$codes = @{
	'Black'       = @{ 'Fore'=30; 'Back'=40 }
	'DarkRed'     = @{ 'Fore'=31; 'Back'=41 }
	'DarkGreen'   = @{ 'Fore'=32; 'Back'=42 }
	'DarkYellow'  = @{ 'Fore'=33; 'Back'=43 }
	'DarkBlue'    = @{ 'Fore'=34; 'Back'=44 }
	'DarkMagenta' = @{ 'Fore'=35; 'Back'=45 }
	'DarkCyan'    = @{ 'Fore'=36; 'Back'=46 }
	'Gray'        = @{ 'Fore'=37; 'Back'=47 }
	'DarkGray'    = @{ 'Fore'=90; 'Back'=100 }
	'Red'         = @{ 'Fore'=91; 'Back'=101 }
	'Green'       = @{ 'Fore'=92; 'Back'=102 }
	'Yellow'      = @{ 'Fore'=93; 'Back'=103 }
	'Blue'        = @{ 'Fore'=94; 'Back'=104 }
	'Magenta'     = @{ 'Fore'=95; 'Back'=105 }
	'Cyan'        = @{ 'Fore'=96; 'Back'=106 }
	'White'       = @{ 'Fore'=97; 'Back'=107 }
}

Write-Host "`nSystem.ConsoleColor :: HKCU:\Console :: -ForegroundColor`n"
Push-Location HKCU:\Console

$colors = [System.Enum]::GetNames([System.ConsoleColor])

For ($i=0; $i -lt $colors.Length; $i++) `
{
	$name = $colors[$i]
	$table = ("ColorTable{0}" -f ($i).ToString('00'))
	$value = (Get-ItemPropertyValue . -name $table)

	$basics = "{0} {1} {2}" -f $table, $value.ToString('X8'), $name
	$decimal = "{0}, {1}, {2}" -f ($value -band 0xff), (($value -band 0xff00) -shr 8), (($value -band 0xff0000) -shr 16)
	$rgb = "{0:X2}{1:X2}{2:X2}" -f ($value -band 0xff), (($value -band 0xff00) -shr 8), (($value -band 0xff0000) -shr 16)
	$escapes = "<ESC>[{0}m" -f $codes[$name].Fore

	if ($name -eq 'Black') {
		Write-Host ("{0,-35} #{1}  {2,-14}  {3}  " -f $basics, $rgb, $decimal, $escapes) -ForegroundColor $name -BackgroundColor DarkGray	-NoNewline
		Write-Host (" <ESC>[{0} " -f $codes[$name].Back) -BackgroundColor $name -ForegroundColor Gray
	}
	else {
		Write-Host ("{0,-35} #{1}  {2,-14}  {3}  " -f $basics, $rgb, $decimal, $escapes) -ForegroundColor $name -NoNewline
		$fore = if ($name -eq 'Gray') { 'DarkGray' } else { 'Gray' }
		Write-Host (" <ESC>[{0}m " -f $codes[$name].Back) -BackgroundColor $name -ForegroundColor $fore
	}
}

Write-Host "`nOther ESCapes: " -ForegroundColor White -NoNewline
Write-Host "<ESC>[0m Reset, $esc[1m<ESC>[1m Bold$esc[0m, $esc[4m<ESC>[4m Underline$esc[0m, $esc[7m<ESC>[7m Inverse$esc[0m`n" -ForegroundColor DarkGray

Pop-Location
