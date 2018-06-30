<#
.SYNOPSIS
Set a custom value for the specified console color table entry.
By default, the all color tables - Command, PowerShell, and ConEmu - are
updated unless one table is specified.

.PARAMETER Name
The name of the color table entry to set. Must be one of the known
System.ConsoleColor enumeration names.

.PARAMETER Color
The RGB or BGR color expressed as a six digit hex value.
The default is RGB unless the -Bgr switch is specified.

.PARAMETER Bgr
Indicates that the Color parameter specifies a BGR value; 
the default is to specify an RGB value.

.PARAMETER Cmd
Update just the Command console color table.

.PARAMETER ConEmu
Update just the ConEmu console color table.

.PARAMETER PS
Update just the PowerShell console color table.

.PARAMETER Background
Set the specified color as the console background color.

.PARAMETER Foreground
Set the specified color as the console foreground color.

.PARAMETER WhatIf
Run the command and report changes but don't make any changes.

.DESCRIPTION
Colors for PowerShell and command windows are stored separately. Command
console colors are stored in the Registry while PowerShell colors are
stored in the shortcut link file used to start the PowerShell console.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[parameter(Position=0, Mandatory=$true, HelpMessage="First parameter is table entry name")]
	[ValidateScript({
		if ([bool]($_ -as [System.ConsoleColor] -is [System.ConsoleColor])) { $true } else {
			Throw 'Name must specify a known System.ConsoleColor name'
		}
	})]
	[string] $Name,

	[parameter(Position=1, Mandatory=$true, HelpMessage="Second parameter is the color hex value")]
	[ValidateScript({
		if ($_ -match '^(0x|#)?[A-Fa-f0-9]{1,6}$') { $true } else {
			Throw 'Value must specify a color hex value of 1-6 characters '
		}
	})]
	[string] $Color,
	[switch] $Bgr,
	[switch] $Cmd,
	[switch] $ConEmu,
	[switch] $PS,
	[switch] $Background,
	[switch] $Foreground
)

Begin
{
	function GetColorIndex ($name)
	{
		# correct for case-sensitivity, find index of name within color table
		return [System.Enum]::GetNames([System.ConsoleColor]).indexOf(($name -as [System.ConsoleColor]).ToString())
	}

	function NormalizeColor ($color)
	{
		if ($color.StartsWith('0x', [System.StringComparison]::InvariantCultureIgnoreCase))
		{
			$color = $color.Substring(2)
		}
		elseif ($color.StartsWith('#'))
		{
			$color = $color.Substring(1)
		}

		return [System.Convert]::ToInt32($color, 16)
	}

	function Reverse ($value)
	{
		# RGB to BGR, or BGR to RGB
		return (($value -band 0xFF0000) -shr 16) + ($value -band 0x00FF00) + (($value -band 0x0000FF) -shl 16)
	}

	function SetCommandColor ()
	{
		$index = GetColorIndex $Name
		$entry = ("ColorTable{0:00}" -f $index)

		$value = NormalizeColor $Color
		if (-not $Bgr) { $value = Reverse $value }

		if ($WhatIfPreference)
		{
			$hex = ("{0:X6}" -f $value).ToUpper()
			Write-Host "CMD: Set-ItemProperty HKCU:\Console -Name $entry -Value $value (#$hex) -Type DWord" -ForegroundColor DarkGray
		}
		else
		{
			Write-Host 'Setting command console color'
			Push-Location HKCU:\Console
			Set-ItemProperty . -Name $entry -Value $value -Type DWord

			if ($Background -or $Foreground)
			{
				$screen =  (Get-ItemPropertyValue . 'ScreenColors')
				if ($Background) { $screen = ($screen -band 0xFFFF) + ($index -shl 16) }
				else { $screen = ($screen -band 0xFFFF0000) + $index }
				Set-ItemProperty . -Name 'ScreenColors' -Value $screen -Type DWord -Force
			}
			Pop-Location
		}
	}

	function SetPowerShellColor ()
	{
		$folder = "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\"

		$index = GetColorIndex $Name

		$value = NormalizeColor $Color
		if ($Bgr) { $value = Reverse $value }

		$rgb = '#' + ("{0:X6}" -f $value).ToUpper()

		# 64-bit shortcut
		$linkpath = "$folder\Windows PowerShell.lnk"
		if (Test-Path $linkpath)
		{
			$link = Get-Link -Path $linkpath
			$link.ConsoleColors[$index] = $rgb

			# set one or the other; don't allow both because that would be stupid
			if ($Background) { $link.ScreenBackgroundColor = $index }
			elseif ($Foreground) { $link.ScreenTextColor = $index }

			#$lnk.PopUpBackgroundColor=0x...
			#$lnk.PopUpTextColor=0x...

			if ($WhatIfPreference) {
				Write-Host "PWS: Update x64 LNK -Name $Name -Index $index -Value $rgb" -ForegroundColor DarkGray
			}
			else {
				Write-Host 'Setting PowerShell console color'
				$link.Save()
			}
		}

		# 32-bit shortcut
		$linkpath = "$folder\Windows PowerShell (x86).lnk"
		if (Test-Path $linkpath)
		{
			$link = Get-Link -Path $linkpath
			$link.ConsoleColors[$index] = $rgb

			if ($WhatIfPreference) {
				Write-Host "PWS: Update x86 LNK -Name $Name -Index $index -Value $rgb" -ForegroundColor DarkGray
			}
			else {
				Write-Host 'Setting PowerShell x86 console color'
				$link.Save()
			}
		}
	}

	function SetConEmuColor ()
	{
		$file = "${env:APPDATA}\ConEmu.xml"
		if (Test-Path $file)
		{
			$index = GetColorIndex $Name
			$entry = ("ColorTable{0:00}" -f $index)

			$value = NormalizeColor $Color	
			if (-not $Bgr) { $value = Reverse $value }

			$value = ("{0:X8}" -f $value).ToUpper()

			$xml = [xml](Get-Content $file)
			$xml | Select-Xml -XPath "//value[@name='$entry']" | % { $_.Node.data = $value }

			if ($Background) {
				$xml | Select-Xml -XPath "//value[@name='BackColorIdx']" | % { $_.Node.data = $index }
			}
			elseif ($Foreground) {
				$xml | Select-Xml -XPath "//value[@name='TextColorIdx']" | % { $_.Node.data = $index }
			}

			if ($WhatIfPreference) {
				Write-Host "EMU: Set attribute $entry to $value" -ForegroundColor DarkGray
			}
			else {
				Write-Host 'Setting ConEmu console color'
				# convert XmlDocument to XElement to output formatted XML better
				$null = [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq")
				$xml = [System.Xml.Linq.XElement]::Parse($xml.OuterXml)
				$xml.Save($file)
			}
		}
	}
}
Process
{
	if ($Cmd)
	{
		SetCommandColor
	}
	elseif ($ConEmu)
	{
		SetConEmuColor
	}
	elseif ($PS)
	{
		SetPowerShellColor
	}
	else
	{
		SetCommandColor
		SetConEmuColor
		SetPowerShellColor
	}
}