<#
.SYNOPSIS
Report the size of all items in the specified folder.
#>
param (
	$dir,
	[System.Management.Automation.SwitchParameter] $la)

$bytes = 0
$count = 0

Get-Childitem $dir -force:$la | Foreach-Object `
{
	if ($_ -is [IO.FileInfo]) {
		$bytes += $_.Length
		$count++
	}
}

Write-Host "`n    " -NoNewline

if ($bytes -ge 1KB -and $bytes -lt 1MB) {
	Write-Host("" + [Math]::Round(($bytes / 1KB), 2) + " KB") -NoNewLine
}
elseif ($bytes -ge 1MB -and $bytes -lt 1GB) {
	Write-Host("" + [Math]::Round(($bytes / 1MB), 2) + " MB") -NoNewLine
}
elseif ($bytes -ge 1GB) {
	Write-Host("" + [Math]::Round(($bytes / 1GB), 2) + " GB") -NoNewLine
}
else {
	Write-Host("" + $bytes + " bytes") -NoNewLine
}
Write-Host " in $count files"
