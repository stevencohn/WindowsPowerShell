<#
.SYNOPSIS
Convert integer values to Hex string. If one integer is specified then it is converted.
If three integers are specified then they are assumed to be RGB values and combined into a 
single Hex string.

.PARAMETER r
Red vlaue or single integer value

.PARAMETER g
Green value, optional.

.PARAMETER b
Blue value, optional.

.DESCRIPTION
If given three values and any are out of the normal RGB range (0-255) then they will be
converted independently into three strings, returned as a single text string.
#>

param(
	[Parameter(Mandatory=$true,Position=0,HelpMessage="One or three parameters required")] [int32] $r,
	[Parameter(Mandatory=$false,Position=1)] [int32] $g,
	[Parameter(Mandatory=$false,Position=2)] [int32] $b
)

if ($b)
{
	if (($r -gt 255) -or ($g -gt 255) -or ($b > 255))
	{
		# can't be RGB because out of range
		Write-Host ("{0},{1},{2} = 0x{3}, 0x{4}, 0x{5}" -f $r, $g, $b, $r.ToString('X'), $g.ToString('X'), $b.ToString('X'))
	}
	else
	{
		# presume $r $g $b are RGB values
		Write-Host ("{0},{1},{2} = 0x00{3}{4}{5}" -f $r, $g, $b, $r.ToString('X2'), $g.ToString('X2'), $b.ToString('X2'))
	}
}
else
{
	Write-Host ("{0} = 0x{1}" -f $r, $r.ToString('X8'))
}
