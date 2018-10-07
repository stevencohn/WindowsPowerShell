<#
.SYNOPSIS
Convert a Hex string into an integer value. If the string contains six
or eight characters then it is also interpreted as an ARGB value and each
component part is displayed.

.PARAMETER Hex
A string specifying a Hex vavlue.
#>
param(
	[string] $Hex
)

$Hex = $Hex.ToUpper()
if ($Hex.StartsWith('0X')) { $Hex = $Hex.Substring(2) }

Write-Host ("`n0x$Hex = {0}" -f [Convert]::ToInt64($Hex, 16))

if ($Hex.Length -eq 6 -or $Hex.Length -eq 8)
{
	Write-Host ''
	$keys = @('A','R','G','B')
	$k = if ($Hex.Length -eq 8) { 0 } else { 1 }
	for ($i = 0; $i -lt $Hex.Length; $i += 2)
	{
		$part = $Hex.Substring($i, 2)
		Write-Host (" {0}: 0x{1} = {2}" -f $keys[$k], $part, [Convert]::ToInt16($part, 16))
		$k++
	}
}
