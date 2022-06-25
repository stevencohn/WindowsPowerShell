<#
.SYNOPSIS
Invoke the Visual Studio environment batch script. Should alias this with 'vs'
#>

$0 = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\Common7\Tools"
if (Test-Path $0)
{
	Push-Location $0
}
else
{
	$0 = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\Common7\Tools"
	if (Test-Path $0)
	{
		Push-Location $0
	}
	else
	{
		Write-Host '... cannot find Visual Studio 2022' -ForegroundColor Red
		return
	}
}

cmd /c "VsDevCmd.bat&set" | ForEach-Object `
{
	if ($_ -match "=") {
		$v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
	}
}

Pop-Location
