
param (
	[parameter(Position=0, Mandatory=$true, HelpMessage="First parameter is table index, 0..15")]
	[ValidateScript({
		if (($_ -ge 0) -and ($_ -le 15)) {
			$true
		}
		else {
			Throw 'Value must be in the range 0-15'
		}
	})]
	[int] $tableIndex,

	[parameter(Position=1, Mandatory=$true, HelpMessage="Second parameter is BGR hex value")]
	[ValidateScript({
		if ($_ -match '^(0x|#)?[A-Fa-f0-9]{1,6}$') {
			$true
		}
		else {
			Throw 'Value must specify a BGR hex value of 1-6 characters '
		}
	})]
	[string] $BGR
)

$name = ('ColorTable{0:00}' -f $tableIndex)

if ($bgr.StartsWith('0x', [System.StringComparison]::InvariantCultureIgnoreCase))
{
	$bgr = $bgr.Substring(2)
}
elseif ($bgr.StartsWith('#'))
{
	$bgr = $bgr.Substring(1)
}

$value = [System.Convert]::ToInt32($bgr, 16)

Push-Location HKCU:\Console
Set-ItemProperty . -Name $name -Value $value -Type DWord
Pop-Location
