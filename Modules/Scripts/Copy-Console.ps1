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
[CmdletBinding(SupportsShouldProcess=$true)]

param(
	[parameter(Position=0, Mandatory=$false)]
	[string] $OutFile,	# output file name, default is clipboard

	[switch] $All,		# if true, get all lines in buffer
	[switch] $Rtf,		# capture as RTF, default is HTML
	[switch] $Trim		# trim lines if true
)

Begin
{
	$font = '9pt Lucida Console'

	# character translations
	$cmap = @{[char]'<' = '&lt;'; [char]'>' = '&gt;'; [char]'&' = '&amp;'}
	#if ($Rtf) { $cmap = @{[char]"`t" = '\tab'; [char]'\' = '\\'; [char]'{' = '\{'; [char]'}' = '\}' } }
	
	# console colour mapping
	$comap = @{
		'Black' = '#1e1e1e'
		'DarkBlue' = '#006291'
		'DarkGreen' = '#008000'
		'DarkCyan' = '#008080'
		'DarkRed' = '#800000'
		'DarkMagenta' = '8000080'
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

	# set default colours
	$defaultfg = $host.UI.RawUI.ForegroundColor
	$defaultbg = $host.UI.RawUI.BackgroundColor
	$fg = $defaultfg
	$bg = $defaultbg

	$builder = New-Object System.Text.StringBuilder
	$null = $builder.Append("<pre style='color:$(col2htm $fg); background-color:$(col2htm $bg); font:$font; margin:0 10pt 0 0; line-height:normal;'>")

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

	$null = $builder.Append('</pre>')

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
