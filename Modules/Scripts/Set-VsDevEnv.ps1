<#
.SYNOPSIS
Invoke the Visual Studio environment batch script. Should alias this with 'vs'
#>

Begin
{
}
Process
{
	$script:pushed = $false

	$0 = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\Common7\Tools"
	if (Test-Path $0)
	{
		Write-Host '... setting environment for Visual Studio 2022 Professional' -fo DarkYellow
		Push-Location $0
		$script:pushed = $true
	}
	else
	{
		$0 = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\Common7\Tools"
		if (Test-Path $0)
		{
			Write-Host '... setting environment for Visual Studio 2022 Enterprise' -fo DarkYellow
			Push-Location $0
			$script:pushed = $true
		}
		else
		{
			Write-Host '... cannot find Visual Studio 2022' -fo Red
			return
		}
	}

	# run the VsDevCmd script and then call SET to dump the env...
	cmd /c "VsDevCmd.bat & SET" | foreach `
	{
		$line = $_

		# first index only
		$index = $line.IndexOf('=')
		if ($index -gt 0 -and $index -lt $line.Length - 1)
		{
			$name = $line.Substring(0, $index)
			$value = $line.Substring($index + 1)

			$def = (Get-Item env:$name -ea:SilentlyContinue).Value
			if ($def -eq $null -or $def -ne $value)
			{
				Write-Host ('{0,-25}' -f $name) -NoNewline
				Write-Host " $value" -fo DarkGray

				Set-Item -Force -Path env:$name -Value "$value"
			}
		}
	}
}
End
{
	if ($pushed)
	{
		Pop-Location
	}
}
