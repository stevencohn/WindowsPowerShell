#------------------------------------------------------------------------------
# Simple function to get the contents of the console buffer as a series of
# lines of text

param(
	[switch] $All,		# if true, get all lines in buffer
	[switch] $Rtf,		# capture as RTF, default is HTML
	[string] $OutFile	# output file name, default is clipboard
)

Begin
{
	$font = '9pt Lucida Console'

	# character translations
	$cmap = @{[char]'<' = '&lt;'; [char]'>' = '&gt;'; [char]'&' = '&amp;'}
	
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

	function GetContents ()
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

		$ui.GetBufferContents($rect)
	}

	function c2h
	{
		return $comap[[string]$args[0]]
	}

	function CopyToClipboard ([string] $buffer)
	{
		$null = [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
		$dataObject = New-Object Windows.Forms.DataObject 

		$dataObject.SetData([Windows.Forms.DataFormats]::UnicodeText, $true, $buffer)
		#$dataObject.SetData([Windows.Forms.DataFormats]::RTF, $true, $rtf)
		$dataObject.SetData([Windows.Forms.DataFormats]::HTML, $true, $buffer)

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

	$cells = GetContents

	# set default colours
	$fg = $ui.ForegroundColor; $bg = $ui.BackgroundColor
	$defaultfg = $fg; $defaultbg = $bg

	$builder = New-Object System.Text.StringBuilder
	$builder.Append("<pre style='color: $(c2h $fg); background-color: $(c2h $bg); font: $font ;'>")

	for ([int]$row = 0; $row -lt $height; $row++ )
	{
		for ([int]$col = 0; $col -lt $width; $col++ )
		{
			$cell = $cells[$row, $col]
			# do we need to change colours?
			$cfg = [string]$cell.ForegroundColor
			$cbg = [string]$cell.BackgroundColor
			if ($fg -ne $cfg -or $bg -ne $cbg)
			{
				if ($fg -ne $defaultfg -or $bg -ne $defaultbg)
				{
					$builder.Append('</span>') # remove any specialisation
					$fg = $defaultfg; $bg = $defaultbg;
				}
				if ($cfg -ne $defaultfg -or $cbg -ne $defaultbg)
				{
					# start a new colour span
					$builder.Append("<span style='color: $(c2h $cfg); background-color: $(c2h $cbg)'>")
				}
				$fg = $cfg
				$bg = $cbg
			}
			$ch = $cell.Character
			$ch2 = $cmap[$ch]; if ($ch2) { $ch = $ch2 }
			$builder.Append($ch)
		}
		#$line #.TrimEnd() # dump the line in the output pipe
		#$line = ''
		$builder.Append([Environment]::NewLine)
	}

	if ($fg -ne $defaultfg -or $bg -ne $defaultbg)
	{
		# close off any specialisation of colour
		builder.Append('</span>')
	}

	$builder.Append('</pre>')

	if ([String]::IsNullOrEmpty($OutFile))
	{
		CopyToClipboard $builder.ToString()
	}
	else
	{
		$builder.ToString() | Out-File $OutFile
	}
}
