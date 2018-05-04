###########################################################################################################
# Get-ConsoleAsRtf.ps1
#
# The script captures console screen buffer up to the current cursor position and returns it in RTF format.
#
# Returns: ASCII-encoded string.
#
# Example:
#
# $rtfFileName = "$env:temp\ConsoleBuffer.rtf"
# .\Get-ConsoleAsRtf | out-file $rtfFileName -encoding ascii
# $null = [System.Diagnostics.Process]::Start("$rtfFileName")
#
# Check the host name and exit if the host is not the Windows PowerShell console host.
if ($host.Name -ne ‘ConsoleHost’)
{
  write-host -ForegroundColor Red "This script runs only in the console host. You cannot run this script in $($host.Name)."
  exit -1
}
# Maps console color name to RTF color index.
# The index of \cf is referencing the color definition in RTF color table.
#
function Get-RtfColorIndex ([string]$color)
{
  switch ($color)
  {
    ‘Black’ { $index = 17 }
    ‘DarkBlue’ { $index = 2 }
    ‘DarkGreen’ { $index = 3 }
    ‘DarkCyan’ { $index = 4 }
    ‘DarkRed’ { $index = 5 }
    ‘DarkMagenta’ { $index = 6 }
    ‘DarkYellow’ { $index = 7 }
    ‘Gray’ { $index = 8 }
    ‘DarkGray’ { $index = 9 }
    ‘Blue’ { $index = 10 }
    ‘Green’ { $index = 11 }
    ‘Cyan’ { $index = 12 }
    ‘Red’ { $index = 13 }
    ‘Magenta’ { $index = 14 }
    ‘Yellow’ { $index = 15 }
    ‘White’ { $index = 16 }
    default
    {
      $index = 0
    }
  }
  return $index
}
# Create RTF block from text using named console colors.
#
function Append-RtfBlock ($text)
{
  $foreColorIndex = Get-RtfColorIndex $currentForegroundColor
  $null = $rtfBuilder.Append("{\cf$foreColorIndex")
  # You can also add \ab* tag here if you want a bold font in the output.
  $backColorIndex = Get-RtfColorIndex $currentBackgroundColor
  $null = $rtfBuilder.Append("\chshdng0\chcbpat$backColorIndex")
  $text = $blockBuilder.ToString()
  $null = $rtfBuilder.Append(" $text}")
}
# Append line break to RTF builder
#
function Append-Break
{
  $backColorIndex = Get-RtfColorIndex $currentBackgroundColor
  $null = $rtfBuilder.Append("\shading0\cbpat$backColorIndex\par`r`n")
}


# Initialize the RTF string builder.
$rtfBuilder = new-object system.text.stringbuilder
# Set the desired font
$fontName = ‘Lucida Console’
# Append RTF header
$null = $rtfBuilder.Append("{\rtf1\fbidis\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fnil\fcharset0 $fontName;}}")
$null = $rtfBuilder.Append("`r`n")
# Append RTF color table which will contain all Powershell console colors.
$null = $rtfBuilder.Append(‘{\colortbl;red0\green0\blue128;\red0\green128\blue0;\red0\green128\blue128;\red128\green0\blue0;\red1\green36\blue86;\red238\green237\blue240;\red192\green192\blue192;\red128\green128\blue128;\red0\green0\blue255;\red0\green255\blue0;\red0\green255\blue255;\red255\green0\blue0;\red255\green0\blue255;\red255\green255\blue0;\red255\green255\blue255;\red0\green0\blue0;}’)
$null = $rtfBuilder.Append("`r`n")
# Append RTF document settings.
$null = $rtfBuilder.Append(‘\viewkind4\uc1\pard\ltrpar\f0\fs23 ‘)
 
# Grab the console screen buffer contents using the Host console API.
$bufferWidth = $host.ui.rawui.BufferSize.Width
$bufferHeight = $host.ui.rawui.CursorPosition.Y
$rec = new-object System.Management.Automation.Host.Rectangle 0,0,($bufferWidth – 1),$bufferHeight
$buffer = $host.ui.rawui.GetBufferContents($rec)
# Iterate through the lines in the console buffer.
for($i = 0; $i -lt $bufferHeight; $i++)
{
  $blockBuilder = new-object system.text.stringbuilder
  # Track the colors to identify spans of text with the same formatting.
  $currentForegroundColor = $buffer[$i, 0].Foregroundcolor
  $currentBackgroundColor = $buffer[$i, 0].Backgroundcolor
  for($j = 0; $j -lt $bufferWidth; $j++)
  {
    $cell = $buffer[$i,$j]
    # If the colors change, generate an RTF span and append it to the RTF string builder.
    if (($cell.ForegroundColor -ne $currentForegroundColor) -or ($cell.BackgroundColor -ne $currentBackgroundColor))
    {
      Append-RtfBlock
      # Reset the block builder and colors.
      $blockBuilder = new-object system.text.stringbuilder
      $currentForegroundColor = $cell.Foregroundcolor
      $currentBackgroundColor = $cell.Backgroundcolor
    }
    # Substitute characters which have special meaning in RTF.
    switch ($cell.Character)
    {
      "`t" { $rtfChar = ‘\tab’ }
      ‘\’ { $rtfChar = ‘\\’ }
      ‘{‘ { $rtfChar = ‘\{‘ }
      ‘}’ { $rtfChar = ‘\}’ }
      default
      {
        $rtfChar = $cell.Character
      }
    }
    $null = $blockBuilder.Append($rtfChar)
  }
  Append-RtfBlock
  Append-Break
}
# Append RTF ending brace.
$null = $rtfBuilder.Append(‘}’)
return $rtfBuilder.ToString()