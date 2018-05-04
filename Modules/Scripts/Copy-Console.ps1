<#
.SYNOPSIS
blah

.PARAMETER All
Blah

.PARAMETER OutFile
Blah

.PARAMETER Rtf
Blah
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[parameter(Position = 0, Mandatory = $false)]
	[string] $OutFile,	# output file name, default is clipboard

	[switch] $All, # if true, get all lines in buffer
	[switch] $Rtf, # capture as RTF, default is HTML
	[switch] $Trim		# trim lines if true
)

Begin
{
	$font = 'Lucida Console'
	$fontSize = '9pt'

	$comap = @{} 	# color map

	# character translations
	$cmap = @{[char]'<' = '&lt;'; [char]'>' = '&gt;'; [char]'&' = '&amp;'}
	#if ($Rtf) { $cmap = @{[char]"`t" = '\tab'; [char]'\' = '\\'; [char]'{' = '\{'; [char]'}' = '\}' } }

	$colors = @{
		'Black' = 0x1e1e1e
		'DarkBlue' = 0x006291
		'DarkGreen' = 0x008000
		'DarkCyan' = 0x008080
		'DarkRed' = 0x800000
		'DarkMagenta' = 0x800080
		'DarkYellow' = 0x808000
		'Gray' = 0xdedede
		'DarkGray' = 0x808080
		'Blue' = 0x178bff
		'Green' = 0x00ff00
		'Cyan' = 0x00ffff
		'Red' = 0xff0000
		'Magenta' = 0xff9158 #orange
		'Yellow' = 0xffff00
		'White' = 0xffffff
	}

	function MakeColorMap ()
	{
		if ($Rtf)
		{
			$map = New-Object System.Text.StringBuilder
			#{\colortbl;red0\green0\blue128;\red0\green128\blue0;
			$null = $map.Append('{\colortbl;')
			foreach ($color in $colors)
			{
				$rgb = $colors[$color]
				$null = $map.Append('\red' + (($rgb -band 0xFF0000) -shr 16))
				$null = $map.Append('\green' + (($rgb -band 0xFF00) -shr 8))
				$null = $map.Append('\blue' + ($rgb -band 0xFF))
			}
			$map = $map.Append('}').ToString()
		}
		else
		{
			$comap = @{}
			foreach ($color in $colors)
			{
				$comap.Add($color, '#' + $colors[$color].ToString('X6'))
			}
		}
	}

	# console colour mapping
	$comap = @{
		'Black' = '#1e1e1e'
		'DarkBlue' = '#006291'
		'DarkGreen' = '#008000'
		'DarkCyan' = '#008080'
		'DarkRed' = '#800000'
		'DarkMagenta' = '#800080'
		'DarkYellow' = '#808000'
		'Gray' = '#dedede'
		'DarkGray' = '#808080'
		'Blue' = '#178bff'
		'Green' = '#00ff00'
		'Cyan' = '#00ffff'
		'Red' = '#ff0000'
		'Magenta' = '#ff9158' #orange
		'Yellow' = '#ffff00'
		'White' = '#ffffff'
	}

	function GetDimensions ()
	{
		$ui = $host.UI.RawUI

		# coordinate 0,0 is at upper left of buffer
		if ($All)
		{
			# get entire contents of console buffer, visible and scrolled
			$bottom = $ui.BufferSize.Height
			$top = 0
		}
		else
		{
			# get only visible contents of console buffer
			$bottom = $ui.CursorPosition.Y
			$top = $bottom - $ui.WindowSize.Height
			if ($top -le 0) { $top = 0 }
		}

		$dims = 0, $top, ($ui.BufferSize.Width - 1), ($bottom - 1)
		$rect = New-Object Management.Automation.Host.Rectangle -ArgumentList $dims
		$rect, ($rect.Right - $rect.Left + 1), ($rect.Bottom - $rect.Top + 1)
	}

	# find the upper and lower boundaries of the buffer - where readable content
	# actually starts because the buffer is a complete rectangle full of spaces.
	# this is must faster than trying to print out all of that whitespace!
	function GetBoundaries ($cells, $width, $height)
	{
		$top = 0
		$found = $false
		for ([int]$r = 0; $r -lt $height -and !$found; $r++)
		{
			for ([int]$c = 0; $c -lt $width -and !$found; $c++)
			{
				$ch = $cells[$r, $c].Character
				$found = -not [String]::IsNullOrWhiteSpace($ch)
				$top = $r
			}
		}

		if ($found)
		{
			$bottom = $height
			$found = $false
			for ([int]$r = $height; $r -gt 0 -and !$found; $r--)
			{
				for ([int]$c = 0; $c -lt $width -and !$found; $c++)
				{
					$ch = $cells[$r, $c].Character
					$found = -not [String]::IsNullOrWhiteSpace($ch)
					$bottom = $r
				}
			}

			return $top, $bottom
		}

		return 0, $height
	}

	function WritePreamble ($builder, $fg, $bg)
	{
		if ($Rtf)
		{
			# Append RTF header
			$null = $builder.Append("{\rtf1\fbidis\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 $font;}}")
			$null = $builder.Append("`r`n")
			# Append RTF color table which will contain all Powershell console colors.
			$null = $builder.Append('{\colortbl;red0\green0\blue128;\red0\green128\blue0;\red0\green128\blue128;\red128\green0\blue0;\red1\green36\blue86;\red238\green237\blue240;\red192\green192\blue192;\red128\green128\blue128;\red0\green0\blue255;\red0\green255\blue0;\red0\green255\blue255;\red255\green0\blue0;\red255\green0\blue255;\red255\green255\blue0;\red255\green255\blue255;\red0\green0\blue0;}')
			$null = $builder.Append("`r`n")
			# Append RTF document settings.
			$null = $builder.Append('\viewkind4\uc1\pard\ltrpar\f0\fs23 ')
		}
		else
		{
			$null = $builder.Append("<pre style='color:$(col2htm $fg); background-color:$(col2htm $bg); font-family:$font; font-size:$fontSize; margin:0 10pt 0 0; line-height:normal;'>")
		}
	}

	function WritePostscript ($builder)
	{
		if (!$Rtf)
		{
			$null = $builder.Append('</pre>')
		}
	}

	function col2htm { $comap[[string]$args[0]] }

	function ch2htm { if ($cmap[[char]$args[0]]) { $cmap[[char]$args[0]] } else { $args[0] } }

	function CopyToClipboard ([string] $buffer)
	{
		$null = [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
		$dataObject = New-Object Windows.Forms.DataObject 

		#$dataObject.SetData([Windows.Forms.DataFormats]::UnicodeText, $true, $buffer)
		$builder.ToString() | Set-Clipboard -AsHtml
		#$dataObject.SetData([Windows.Forms.DataFormats]::RTF, $true, $rtf)
		#$dataObject.SetData([Windows.Forms.DataFormats]::HTML, $true, $buffer)

		[Windows.Forms.Clipboard]::SetDataObject($dataObject, $true)
	}
}
Process
{
	if ($host.Name -ne 'ConsoleHost')
	{
		Write-Host -ForegroundColor Yellow 'Copy-Console only works from the Console command line'
		exit -1
	}

	$box, $width, $height = GetDimensions
	Write-Verbose("region top {0} left {1} bottom {2} right {3} ... width {4} height {5}" -f `
			$box.Top, $box.Left, $box.Bottom, $box.Right, $width, $height)

	$cells = $host.UI.RawUI.GetBufferContents($box)
	Write-Verbose("contents has {0} characters" -f $cells.Length)

	$top, $bottom = GetBoundaries $cells $width $height
	Write-Verbose("boundaries top {0} bottom {1}" -f $top, $bottom)

	$defaultfg = $host.UI.RawUI.ForegroundColor
	$defaultbg = $host.UI.RawUI.BackgroundColor
	$fg = $defaultfg
	$bg = $defaultbg

	$builder = New-Object System.Text.StringBuilder
	WritePreamble $builder $fg $bg

	for ([int]$row = $top; $row -lt $bottom; $row++)
	{
		$line = New-Object System.Text.StringBuilder
		for ([int]$col = 0; $col -lt $width; $col++)
		{
			$cell = $cells[$row, $col]
			# do we need to change colours?
			$cfg = [string]$cell.ForegroundColor
			$cbg = [string]$cell.BackgroundColor
			if ($fg -ne $cfg -or $bg -ne $cbg)
			{
				if ($fg -ne $defaultfg -or $bg -ne $defaultbg)
				{
					$null = $line.Append('</span>') # remove any specialisation
					$fg = $defaultfg; $bg = $defaultbg;
				}
				if ($cfg -ne $defaultfg -or $cbg -ne $defaultbg)
				{
					# start a new colour span
					$null = $line.Append("<span style='color: $(col2htm $cfg); background-color: $(col2htm $cbg)'>")
				}
				$fg = $cfg
				$bg = $cbg
			}
			$ch = ch2htm $cell.Character
			$null = $line.Append($ch)
		}

		$line = if ($Trim) { $line.ToString().Trim() } else { $line.ToString() }
		$null = $builder.Append($line).Append([Environment]::NewLine)
	}

	$null = $builder.Append([Environment]::NewLine)

	if ($fg -ne $defaultfg -or $bg -ne $defaultbg)
	{
		# close off any specialisation of colour
		builder.Append('</span>')
	}

	WritePostscript $builder

	if ($WhatIfPreference)
	{
		Write-Host $builder.ToString()
	}
	elseif ([String]::IsNullOrEmpty($OutFile))
	{
		CopyToClipboard $builder.ToString()
	}
	else
	{
		$builder.ToString() | Out-File $OutFile
	}
}
