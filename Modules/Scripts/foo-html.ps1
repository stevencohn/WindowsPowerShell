############################################################################################################
# Get-ConsoleAsHtml.ps1
#
# The script captures console screen buffer up to the current cursor position and returns it in HTML format.
#
# Returns: UTF8-encoded string.
#
# Example:
#
# $htmlFileName = "$env:temp\ConsoleBuffer.html"
# .\Get-ConsoleAsHtml | out-file $htmlFileName -encoding UTF8
# $null = [System.Diagnostics.Process]::Start("$htmlFileName")
#
# Check the host name and exit if the host is not the Windows PowerShell console host.
if ($host.Name -ne ‘ConsoleHost’)
{
	write-host -ForegroundColor Red "This script runs only in the console host. You cannot run this script in $($host.Name)."
	exit -1
}
# The Windows PowerShell console host redefines DarkYellow and DarkMagenta colors and uses them as defaults.
# The redefined colors do not correspond to the color names used in HTML, so they need to be mapped to digital color codes.
#
function Normalize-HtmlColor ($color)
{
	if ($color -eq "DarkYellow") { $color = "#eeedf0" }
	if ($color -eq "DarkMagenta") { $color = "#012456" }
	return $color
}
# Create an HTML span from text using the named console colors.
#
function Make-HtmlSpan ($text, $forecolor = "DarkYellow", $backcolor = "DarkMagenta")
{
	$forecolor = Normalize-HtmlColor $forecolor
	$backcolor = Normalize-HtmlColor $backcolor
	# You can also add font-weight:bold tag here if you want a bold font in output.
	return "<span style=’font-family:Courier New;color:$forecolor;background:$backcolor’>$text</span>"
}
# Generate an HTML span and append it to HTML string builder
#
function Append-HtmlSpan
{
	$spanText = $spanBuilder.ToString()
	$spanHtml = Make-HtmlSpan $spanText $currentForegroundColor $currentBackgroundColor
	$null = $htmlBuilder.Append($spanHtml)
}
# Append line break to HTML builder
#
function Append-HtmlBreak
{
	$null = $htmlBuilder.Append("<br>")
}
# Initialize the HTML string builder.
$htmlBuilder = new-object system.text.stringbuilder
$null = $htmlBuilder.Append("<pre style=’MARGIN: 0in 10pt 0in;line-height:normal’;font-size:10pt>")
# Grab the console screen buffer contents using the Host console API.
$bufferWidth = $host.ui.rawui.BufferSize.Width
$bufferHeight = $host.ui.rawui.CursorPosition.Y
$rec = new-object System.Management.Automation.Host.Rectangle 0, 0, ($bufferWidth – 1), $bufferHeight
$buffer = $host.ui.rawui.GetBufferContents($rec)
# Iterate through the lines in the console buffer.
for ($i = 0; $i -lt $bufferHeight; $i++)
{
	$spanBuilder = new-object system.text.stringbuilder
	# Track the colors to identify spans of text with the same formatting.
	$currentForegroundColor = $buffer[$i, 0].Foregroundcolor
	$currentBackgroundColor = $buffer[$i, 0].Backgroundcolor
	for ($j = 0; $j -lt $bufferWidth; $j++)
 {
		$cell = $buffer[$i, $j]
		# If the colors change, generate an HTML span and append it to the HTML string builder.
		if (($cell.ForegroundColor -ne $currentForegroundColor) -or ($cell.BackgroundColor -ne $currentBackgroundColor))
		{
			Append-HtmlSpan
			# Reset the span builder and colors.
			$spanBuilder = new-object system.text.stringbuilder
			$currentForegroundColor = $cell.Foregroundcolor
			$currentBackgroundColor = $cell.Backgroundcolor
		}
		# Substitute characters which have special meaning in HTML.
		switch ($cell.Character)
		{
			‘>’ { $htmlChar = ‘&gt;’ }
			‘<‘ { $htmlChar = ‘&lt;’ }
			‘&’ { $htmlChar = ‘&amp;’ }
			default
			{
				$htmlChar = $cell.Character
			}
		}
		$null = $spanBuilder.Append($htmlChar)
	}
	Append-HtmlSpan
	Append-HtmlBreak
}
# Append HTML ending tag.
$null = $htmlBuilder.Append("</pre>")
return $htmlBuilder.ToString()