<#
.SYNOPSIS
Convert a BinHex encoded string back to its original string value.

.PARAMETER Hex
A string specifying a BinHex encoded string.

.PARAMETER Unicode
Use unicode encoding. Default is to use ASCII encoding.
#>
param(
	[string] $Hex,
	[switch] $Unicode
)

Begin
{
	function Decode
	{
		$data = [System.Convert]::FromBase64String($hex)

		if ($Unicode)
		{
			return [System.Text.UnicodeEncoding]::Unicode.GetString($data)
		}

		return [System.Text.ASCIIEncoding]::ASCII.GetString($data)
	}
}
Process
{
	Decode
}

<#
#Example of converting ASCII to Unicode; can reverse it to convert Unicode to ASCII

$bytes = [System.Text.Encoding]::Convert( `
            [System.Text.Encoding]::ASCII, `
            [System.Text.Encoding]::Unicode, `
            [System.Text.Encoding]::ASCII.GetBytes('this is a string'))

$text = [System.Text.UnicodeEncoding]::Unicode.GetString($bytes)
#>