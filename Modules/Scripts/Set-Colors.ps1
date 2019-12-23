<#
.SYNOPSIS
Set the color theme for command line consoles or set a specific named color.
By default, updates all colors tables for Command, PowerShell, and if installed
ConEmu.

.PARAMETER Name
The name of the color table entry to set. Must be one of the known
System.ConsoleColor enumeration names. -Name and -Color are mutually exclusive
with -Theme.

.PARAMETER Color
The RGB or BGR color expressed as a six digit hex value.
The default is RGB unless the -Bgr switch is specified. -Color and -Name are
mutually exclusive with -Theme.

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

.PARAMETER Theme
Apply the specified theme file from the Themes folder; this folder must be
relative to this script and named ..\Themes\Theme_<name>.json. -Theme is
mutually exclusive with -Name and -Color.

.PARAMETER Verbose
Report each setting as it is changed; default is to run silently.

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
	[Parameter(ParameterSetName="Color", Position=0, Mandatory=$true, HelpMessage="First parameter is table entry name")]
	[ValidateScript({
		if ([bool]($_ -as [System.ConsoleColor] -is [System.ConsoleColor])) { $true } else {
			Throw 'Name must specify a known System.ConsoleColor name'
		}
	})]
	[string] $Name,

	[parameter(ParameterSetName="Color", Position=1, Mandatory=$true, HelpMessage="Second parameter is the color hex value")]
	[ValidateScript({
		if ($_ -match '^(0x|#)?[A-Fa-f0-9]{1,6}$') { $true } else {
			Throw 'Value must specify a color hex value of 1-6 characters '
		}
	})]
	[string] $Color,

	[Parameter(ParameterSetName="Color")]
	[switch] $Bgr,

	[Parameter(ParameterSetName="Color")]
	[switch] $Background,

	[Parameter(ParameterSetName="Color")]
	[switch] $Foreground,

	[Parameter(ParameterSetName="Theme", HelpMessage="Name of a theme")]
	[ValidateScript({
		$p = Split-Path $Script:MyInvocation.MyCommand.Path -Parent | Split-Path -Parent | Split-Path -Parent
		$t = Join-Path $p "Themes\Theme_$_.json"
		if (Test-Path $t) { $true } else {
			Write-Host "Cannot find $t" -ForegroundColor Yellow
			Throw "Theme must specify a known theme file, e.g. ..\Themes\Theme_<name>.json $p"
		}
	})]
	[string] $Theme,

	[switch] $Cmd,
	[switch] $ConEmu,
	[switch] $PS
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
			Write-Verbose "Setting command console color $Name to $value ($entry)"
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
				Write-Verbose "Setting PowerShell console color $Name to $value"
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
				Write-Verbose 'Setting PowerShell x86 console color'
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
				$xml | Select-Xml -XPath "//value[@name='BackColorIdx']" | % { 
					$_.Node.data = "{0:X2}" -f $index
				}
			}
			elseif ($Foreground) {
				$xml | Select-Xml -XPath "//value[@name='TextColorIdx']" | % {
					$_.Node.data = "{0:X2}" -f $index
				}
			}

			if ($WhatIfPreference) {
				Write-Host "EMU: Set attribute $entry to $value" -ForegroundColor DarkGray
			}
			else {
				Write-Verbose "Setting ConEmu console color $Name to $value"
				# convert XmlDocument to XElement to output formatted XML better
				$null = [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq")
				$xml = [System.Xml.Linq.XElement]::Parse($xml.OuterXml)
				$xml.Save($file)
			}
		}
		elseif ($ConEmu) # only show warning if requested ConEmu
		{
			Write-Host "*** ConEmu config file not found: $file" -ForegroundColor Yellow
		}
	}

	function SetTheme ()
	{
		$p = Split-Path $Script:MyInvocation.MyCommand.Path -Parent | Split-Path -Parent | Split-Path -Parent
		$file = Join-Path $p "Themes\Theme_$Theme.json"
		$props = Get-Content $file | ConvertFrom-Json

		$bg = 'Black'
		if ($props.Background) { $bg = $props.Background }

		$fg = 'White'
		if ($props.Foreground) { $fg = $props.Foreground }

		$names = [System.Enum]::GetNames([System.ConsoleColor])

		0..15 | % `
		{
			$script:Name = $names[$_]
			if ($props.$Name)
			{
				$script:Color = $props.$Name
				$script:Background = ($bg -eq $Name)
				$script:Foreground = ($fg -eq $Name)

				if ($Cmd) {
					SetCommandColor
				}
				elseif ($ConEmu) {
					SetConEmuColor
				}
				elseif ($PS) {
					SetPowerShellColor
				}
				else {
					SetCommandColor
					SetConEmuColor
					SetPowerShellColor
				}
			}
		}

		if ($props.FaceName) {
			Write-Verbose "Setting FaceName to '$($props.FaceName)'"
			Set-ItemProperty HKCU:\Console -Name 'FaceName' -Value $props.FaceName -Force
		}

		if ($props.FontSize) {
			$size = [System.Convert]::ToInt16($props.Fontsize, 16)
			$size = "$($size.ToString('X4'))0000"
			Write-Verbose "Setting FontSize to '$size'"
			Set-ItemProperty HKCU:\Console -Name 'FontSize' -Value $props.FontSize -Force
		}

		# history=100, rows=9999
		#Set-ItemProperty HKCU:\Console -Name 'HistoryBufferSize' -Value 0x64 -Force
		#Set-ItemProperty HKCU:\Console -Name 'ScreenBufferSize' -Value 0x2329008c -Force
	}
}
Process
{
	if ($Theme)
	{
		SetTheme
		return
	}

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