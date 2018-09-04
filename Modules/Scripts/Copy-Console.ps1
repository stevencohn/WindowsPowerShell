<#
.SYNOPSIS
Copy the contents of the Powershell console window preserving color.

.PARAMETER All
Copy the entire buffer includng areas scrolled out of view. 
Default is the copy only visible content.

.PARAMETER OutFile
Copy content to specified output file.
Default is to copy to clipboard.

.PARAMETER Rtf
Copy content as Rich Text Format (RTF).
Default is to copy as HTML.

.PARAMETER Trim
Trim all lines if true. Default is to trim to a minimal rectangular region.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[parameter(Position = 0, Mandatory = $false)]
	[string] $OutFile,	# output file name, default is clipboard

	[switch] $All,		# if true, get all lines in buffer
	[switch] $Rtf,		# capture as RTF, default is HTML
	[switch] $Trim		# trim lines if true
)

Begin
{
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
		'Magenta' = 0xff9158 # customize as orange
		'Yellow' = 0xffff00
		'White' = 0xffffff
	}

	$font = 'Lucida Console'
	$fontSize = 9

	# color map
	$comap = @{}
	$rawForeground = $host.UI.RawUI.ForegroundColor
	$rawBackground = $host.UI.RawUI.BackgroundColor

	# character translations
	$cmap = @{[char]'<' = '&lt;'; [char]'>' = '&gt;'; [char]'&' = '&amp;'}
	if ($Rtf) { $cmap = @{[char]"`t" = '\tab'; [char]'\' = '\\'; [char]'{' = '\{'; [char]'}' = '\}' } }

	function MakeColorMap ()
	{
		if ($Rtf)
		{
			# we're not using background colors so darken Yellow so we can see it
			$colors['Yellow'] = 0xFFC000
			
			$map = New-Object System.Text.StringBuilder
			#{\colortbl;red0\green0\blue128;\red0\green128\blue0;
			$null = $map.Append('{\colortbl;')
			foreach ($color in $colors.Keys)
			{
				$rgb = $colors[$color]
				$null = $map.Append('\red' + (($rgb -band 0xFF0000) -shr 16))
				$null = $map.Append('\green' + (($rgb -band 0xFF00) -shr 8))
				$null = $map.Append('\blue' + ($rgb -band 0xFF) + ';')
			}
			$map = $map.Append('}').ToString()
		}
		else
		{
			$map = @{}
			foreach ($color in $colors.Keys)
			{
				$map.Add($color, '#' + $colors[$color].ToString('X6'))
			}
		}

		$map
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
		$top = -1
		for ([int]$r = 0; $r -lt $height -and $top -lt 0; $r++) {
			for ([int]$c = 0; $c -lt $width -and $top -lt 0; $c++) {
				$ch = $cells[$r, $c].Character
				if (![String]::IsNullOrWhiteSpace($ch)) { $top = $r }
			}
		}

		if ($top -lt 0) { return 0, $height }

		$bottom = -1
		for ([int]$r = $height; $r -gt 0 -and $bottom -lt 0; $r--) {
			for ([int]$c = 0; $c -lt $width -and $bottom -lt 0; $c++) {
				$ch = $cells[$r, $c].Character
				if (![String]::IsNullOrWhiteSpace($ch)) { $bottom = $r }
			}
		}

		return $top, $bottom
	}

	function StartColor ($builder, [string]$fg, [string]$bg)
	{
		if ($Rtf)
		{
			$index = [Array]::IndexOf($colors.Keys, $fg) + 1
			$null = $builder.Append("{\cf$index")
			# You can also add \ab* tag here if you want a bold font in the output.
			
			#... don't know how to set page background so we're just ignore it for now
			#$index = [Array]::IndexOf($colors.Keys, $bg) + 1
			#$null = $builder.Append("\chshdng0\chcbpat$index")
		}
		else
		{
			$fc = $comap[$fg]
			$bc = $comap[$bg]
			$null = $line.Append("<span style='color:$fc; background-color:$bc'>")
		}

		$fg, $bg
	}

	function EndColor ($builder)
	{
		if ($Rtf) { $null = $builder.Append('}') } else { $null = $builder.Append('</span>') }

		$rawForeground, $rawBackground
	}

	function MakeContent ($lines, $mintrim, $width)
	{
		$builder = New-Object System.Text.StringBuilder
		WritePreamble $builder $foreground $background

		$mintrim -= 2
		$dotrim = ($mintrim -lt ($width - 2)) -and -not $Trim

		$eol = if ($Rtf) { '\line' + [Environment]::Newline } else { [Environment]::NewLine }

		foreach ($line in $lines)
		{
			if ($dotrim -and ($mintrim -gt $line.length)) {
				$line = $line.Substring(0, $line.Length - $mintrim)
			}
			$null = $builder.Append($line + $eol)
		}

		WritePostscript $builder

		$builder.ToString()
	}

	function WritePreamble ($builder, [string]$fg, [string]$bg)
	{
		if ($Rtf)
		{
			# Append RTF header
			$null = $builder.Append("{\rtf1\fbidis\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 $font;}}")
			$null = $builder.Append("`r`n")
			# Append RTF color table which will contain all Powershell console colors.
			$null = $builder.Append($comap)
			$null = $builder.Append("`r`n")
			# Append RTF document settings.
			$null = $builder.Append("\viewkind4\uc1\pard\ltrpar\f0\fs$($fontSize * 2) ")
		}
		else
		{
			$null = $builder.Append("<pre style='color:$($comap[$fg]); background-color:$($comap[$bg]); font-family:$font; font-size:$($fontSize)pt; margin:0 10pt 0 0; line-height:normal;'>")
		}

		$null = $builder.Append([Environment]::NewLine)
	}

	function WritePostscript ($builder)
	{
		if ($Rtf) { $null = $builder.Append('}') } else { $null = $builder.Append('</pre>') }
	}

	function ch2htm { if ($cmap[[char]$args[0]]) { $cmap[[char]$args[0]] } else { $args[0] } }

	function CopyToClipboard ([string] $buffer)
	{
		if ($Rtf)
		{
			$null = [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
			$clip = New-Object Windows.Forms.DataObject 
			$clip.SetText($buffer, [Windows.Forms.TextDataFormat]::Rtf)
			[Windows.Forms.Clipboard]::SetDataObject($clip, $true)
		}
		else
		{
			$buffer | Set-Clipboard -AsHtml
		}
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

	$comap = MakeColorMap

	$lines = @()
	$mintrim = $width

	$foreground = $rawForeground
	$background = $rawBackground

	for ($r = $top; $r -lt $bottom; $r++)
	{
		$line = New-Object System.Text.StringBuilder
		$raw = New-Object System.Text.StringBuilder
		for ($c = 0; $c -lt $width; $c++)
		{
			$cell = $cells[$r, $c]
			if ($foreground -ne $cell.ForegroundColor -or $background -ne $cell.BackgroundColor)
			{
				if ($foreground -ne $rawForeground -or $background -ne $rawBackground) {
					$foreground, $background = EndColor $line
				}

				if ($cell.ForegroundColor -ne $rawForeground -or $cell.BackgroundColor -ne $rawBackground) {
					$foreground, $background = StartColor $line $cell.ForegroundColor $cell.BackgroundColor
				}
			}

			$ch = ch2htm $cell.Character
			$null = $line.Append($ch)
			$null = $raw.Append($cell.Character)
		}

		$line = if ($Trim) { $line.ToString().Trim() + ' ' } else { $line.ToString() }
		$lines += $line

		$rawline = $raw.ToString()
		$rawtrim = $rawline.Length - $rawline.TrimEnd().Length
		if ($rawtrim -lt $mintrim) { $mintrim = $rawtrim }
	}

	if ($fg -ne $defaultfg -or $bg -ne $defaultbg)
	{
		# close off any specialisation of colour
		$lines += '</span>'
	}

	$content = MakeContent $lines $mintrim $width

	if ($WhatIfPreference)
	{
		Write-Host $content
	}
	elseif ([String]::IsNullOrEmpty($OutFile))
	{
		CopyToClipboard $content
	}
	else
	{
		$content | Out-File $OutFile -Encoding ASCII
	}
}
