<#
.SYNOPSIS
Set a custom value for the specified Console color table entry.

.PARAMETER Name
The name of the color table entry to set. Must be one of the known
System.ConsoleColor enumeration names.

.PARAMETER Color
The RGB or BGR color expressed as a six digit hex value.
The default is RGB unless the -Bgr switch is specified.

.PARAMETER Bgr
Indicates that the Color parameter specifies a BGR value; 
the default is to specify an RGB value.

.PARAMETER WhatIf
Run the command and report changes but don't make any changes.
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
	[switch] $Bgr
)

# correct for case-sensitivity, find index of name within color table
$index = [System.Enum]::GetNames([System.ConsoleColor]).indexOf(($Name -as [System.ConsoleColor]).ToString())

$entry = ("ColorTable{0:00}" -f $index)

if ($color.StartsWith('0x', [System.StringComparison]::InvariantCultureIgnoreCase))
{
	$color = $color.Substring(2)
}
elseif ($color.StartsWith('#'))
{
	$color = $color.Substring(1)
}

$value = [System.Convert]::ToInt32($color, 16)

if (-not $Bgr)
{
	# convert RGB to BGR
	$value = (($value -band 0xFF0000) -shr 16) + ($value -band 0x00FF00) + (($value -band 0x0000FF) -shl 16)
}

if ($WhatIfPreference)
{
	Write-Host "Set-ItemProperty HKCU:\Console -Name $entry -Value $value -Type DWord" -ForegroundColor DarkGray
}
else
{
	Push-Location HKCU:\Console
	Set-ItemProperty . -Name $entry -Value $value -Type DWord
	Pop-Location
}