<#
.SYNOPSIS
Display the console colors. Default is to show the color table for the PowerShell
console only.

.PARAMETER All
Display colors for all consoles.

.PARAMETER Cmd
Display colors for the Windows Command console only.

.PARAMETER ConEmu
Display colors for the ConEmu Command console only.

.PARAMETER PS
Display colors for the PowerShell console only.

.PARAMETER Script
Generate a script to set the entire color table.

.DESCRIPTION
Registry values are stored as B-G-R DWord values. This command displays the BGR
value as well as the RGB, decimal equivalents, and console Esc sequences.
#>

param (
	[switch] $All,
	[switch] $Cmd,
	[switch] $PS,
	[switch] $ConEmu,
	[switch] $Script)

Begin
{
	# unicode box characters
	$topleft = ([char]0x250C).ToString()
	$topright = ([char]0x2510).ToString()
	$bottomleft = ([char]0x2514).ToString()
	$bottomright  = ([char]0x2518).ToString()
	$horizontal = ([char]0x2500).ToString()
	$vertical = ([char]0x2502).ToString()

	$esc = [char]27
	$colors = [System.Enum]::GetNames([System.ConsoleColor])

	$ConEmuFile = "${env:APPDATA}\ConEmu.xml"

	function Box ($text)
	{
		$max = 85
		#$max = 0
		#foreach ($s in $text) { if ($s.Length -gt $max) { $max = $s.Length } }

		Write-Host
		Write-Host($topleft + ($horizontal * ($max + 2)) + $topright)

		foreach ($s in $text) {
			Write-Host($vertical + ' ' + ("{0,-$max}" -f $s) + ' ' + $vertical)
		}

		Write-Host($bottomleft + ($horizontal * ($max + 2)) + $bottomright)
		Write-Host
	}

	function ShowCommandColors ()
	{
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

		Box @(
			'Command Console Colors',
			'  System.ConsoleColor :: HKCU:\Console :: -ForegroundColor')

		Write-Host 'Name         BGR      ConsoleColor  RGB      Decimal         Escape Sequence'

		Push-Location HKCU:\Console

		For ($i=0; $i -lt $colors.Length; $i++)
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
	}

	function ShowPowerShellColors ()
	{
		Box @(
			'PowerShell Console Colors',
			'  $env:APPDATA +',
			'    .\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk')

		$menupath = "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk"

		Write-Host 'Known Name            ConsoleColor  RGB      Decimal'

		$link = Get-Link -Path $menupath

		For ($i=0; $i -lt $colors.Length; $i++)
		{
			$name = $colors[$i]
			$lolor = $link.ConsoleColors[$i]
			$rgb = "{0:X2}{1:X2}{2:X2}" -f $lolor.R, $lolor.G, $lolor.B
			$decimal = "{0}, {1}, {2}" -f $lolor.R, $lolor.G, $lolor.B

			if ($name -eq 'Black') {
				Write-Host ("{0,-21} {1,-13} #{2}  {3,-14}" -f $lolor.Name, $name, $rgb, $decimal) -ForegroundColor $name -BackgroundColor DarkGray
			}
			else {
				Write-Host ("{0,-21} {1,-13} #{2}  {3,-14}" -f $lolor.Name, $name, $rgb, $decimal) -ForegroundColor $name
			}
		}
	}

	function ShowConEmuColors ()
	{
		if (Test-Path $ConEmuFile)
		{
			Box @('ConEmu Color Table', "  $ConEmuFile")
			Write-Host 'Name         BGR      ConsoleColor  RGB      Decimal'

			$xml = [xml](Get-Content $ConEmuFile) | Select-Xml `
				-XPath "//key[@name='Software']/key[@name='ConEmu']/key[@name='.Vanilla']/value" | `
				? { $_.Node.Name -like 'ColorTable*' } | % `
				{
					$index = [System.Int32]::Parse($_.Node.Name.Substring(10))
					if ($index -lt 16)
					{
						$name = $colors[$index]
						$bgr = [System.Convert]::ToInt32($_.Node.Data, 16)
						$rgb = (($bgr -band 0xFF0000) -shr 16) + ($bgr -band 0x00FF00) + (($bgr -band 0x0000FF) -shl 16)
						$basics = "{0} {1} {2}" -f $_.Node.Name, $bgr.ToString('X8'), $name
						$decimal = "{0}, {1}, {2}" -f ($bgr -band 0xff), (($bgr -band 0xff00) -shr 8), (($bgr -band 0xff0000) -shr 16)

						if ($name -eq 'Black') {
							Write-Host ("{0,-35} #{1:X6}  {2,-14}" -f $basics, $rgb, $decimal) -ForegroundColor $name -BackgroundColor DarkGray
						}
						else {
							Write-Host ("{0,-35} #{1:X6}  {2,-14}" -f $basics, $rgb, $decimal) -ForegroundColor $name
						}
					}
				}
		}
	}

	function GenerateSetScript ()
	{
		if (!($Cmd -or $ConEmu -or $PS))
		{
			if (Test-Path $ConEmuFile) { $ConEmu = $true }
			else { $PS = $true }
		}

		if ($ConEmu -and (Test-Path $ConEmuFile))
		{
			write-host '# ConEmu color table'
			[xml](Get-Content $ConEmuFile) | Select-Xml `
				-XPath "//key[@name='Software']/key[@name='ConEmu']/key[@name='.Vanilla']/value" | `
				? { $_.Node.Name -like 'ColorTable*' } | % `
				{
					$index = [System.Int32]::Parse($_.Node.Name.Substring(10))
					if ($index -lt 16)
					{
						$name = $colors[$index]
						$bgr = [System.Convert]::ToInt32($_.Node.Data, 16)
						Write-Host ('Set-Color -Name {0} -Color 0x{1:X6} -Bgr' -f $name, $bgr)
					}
				}
		}
		elseif ($Cmd)
		{
			write-host '# CMD color table'
			Push-Location HKCU:\Console
			For ($i=0; $i -lt $colors.Length; $i++)
			{
				$name = $colors[$i]
				$table = ("ColorTable{0}" -f ($i).ToString('00'))
				$value = (Get-ItemPropertyValue . -name $table)
				Write-Host ('Set-Color -Name {0} -Color 0x{1:X6} -Bgr' -f $name, $value)
			}
			Pop-Location
		}
		else
		{
			write-host '# PowerShell color table'
			$menupath = "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk"
			$link = Get-Link -Path $menupath
			For ($i=0; $i -lt $colors.Length; $i++)
			{
				$name = $colors[$i]
				$lolor = $link.ConsoleColors[$i]
				$rgb = "{0:X2}{1:X2}{2:X2}" -f $lolor.R, $lolor.G, $lolor.B
				Write-Host ('Set-Color -Name {0} -Color 0x{1:X6}' -f $name, $rgb)
			}
		}
	}
}
Process
{
	if ($Script)
	{
		GenerateSetScript
	}
	elseif ($Cmd)
	{
		ShowCommandColors
	}
	elseif ($ConEmu)
	{
		ShowConEmuColors
	}
	elseif ($PS)
	{
		ShowPowerShellColors
	}
	elseif ($All)
	{
		ShowPowerShellColors
		ShowCommandColors
		ShowConEmuColors
	}
	else
	{
		ShowPowerShellColors
	}
}
