
<#
.SYNOPSIS
Set the prompt to a colorized string customized by elevation
#>
function prompt {
	$saveCode = $LASTEXITCODE
	if (Confirm-Elevated) {
		Write-Host "PS " -NoNewline -ForegroundColor Red
		Write-Host $pwd -NoNewline -ForegroundColor Blue
	}
	else {
		Write-Host "PS $pwd" -NoNewline -ForegroundColor Blue
	}

	$global:LASTEXITCODE = $saveCode
	return "> "
}


#=======================================================================================
# Aliases
#---------------------------------------------------------------------------------------

New-Alias ep Invoke-EditProfile
New-Alias su Invoke-SuperUser
New-Alias vs Invoke-VsDevCmd
New-Alias cc Show-ColorizedContent

# Docker helpers
New-Alias doc Invoke-DockerClean
New-Alias dos Invoke-DockerShow


#=======================================================================================
# Get-ColorDir (ls)
#---------------------------------------------------------------------------------------

New-CommandWrapper Out-Default -Process {
	$nocase = ([Text.RegularExpressions.RegexOptions]::IgnoreCase)
	$compressed = New-Object Text.RegularExpressions.Regex('\.(zip|tar|gz|iso)$', $nocase)
	$executable = New-Object Text.RegularExpressions.Regex('\.(exe|bat|cmd|msi|ps1|psm1)$', $nocase)

	if (($_ -is [IO.DirectoryInfo]) -or ($_ -is [IO.FileInfo])) {
		if (-not ($notfirst)) {
			$parent = [IO.Path]::GetDirectoryName($_.FullName)
			Write-Host "`n    Directory: $parent`n"
			Write-Host "Mode        Last Write Time       Length   Name"
			Write-Host "----        ---------------       ------   ----"
			$notfirst = $true
		}

		if ($_ -is [IO.DirectoryInfo]) {
			Write-Host ("{0}   {1}               " -f $_.mode, ([String]::Format("{0,10} {1,8}", $_.LastWriteTime.ToString("d"), $_.LastWriteTime.ToString("t")))) -NoNewline
			Write-Host $_.name -ForegroundColor "Blue"
		}
		else {
			if ($compressed.IsMatch($_.Name)) {
				$color = "Magenta"
			}
			elseif ($executable.IsMatch($_.Name)) {
				$color = "DarkGreen"
			}
			else {
				$color = "Gray"
			}
			Write-Host ("{0}   {1}   {2,10}  " -f $_.mode, ([String]::Format("{0,10} {1,8}", $_.LastWriteTime.ToString("d"), $_.LastWriteTime.ToString("t"))), $_.length) -NoNewline
			Write-Host $_.name -ForegroundColor $color
		}

		$_ = $null
	}
} -end {
	Write-Host
}

function Get-DirSize {
	param ($dir,
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
		Write-Host ("" + [Math]::Round(($bytes / 1KB), 2) + " KB") -NoNewLine
	}
	elseif ($bytes -ge 1MB -and $bytes -lt 1GB) {
		Write-Host ("" + [Math]::Round(($bytes / 1MB), 2) + " MB") -NoNewLine
	}
	elseif ($bytes -ge 1GB) {
		Write-Host ("" + [Math]::Round(($bytes / 1GB), 2) + " GB") -NoNewLine
	}
	else {
		Write-Host ("" + $bytes + " bytes") -NoNewLine
	}
	Write-Host " in $count files"
}

function Get-ColorDir {
	param ($dir,[System.Management.Automation.SwitchParameter] $la)
	Get-Childitem $dir -force:$la
	Get-DirSize $dir -la:$la
}

Remove-Item alias:dir
Remove-Item alias:ls
Set-Alias dir Get-ColorDir
Set-Alias ls Get-ColorDir

#=======================================================================================
# OK, Go!

# Chocolatey profile (added by Chocolatey installer)
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
	Import-Module "$ChocolateyProfile"
}

# run vsdevcmd.bat if $env:vsdev is set; this is done by conemu task definition
if ($env:vsdev -eq '1') {
	Invoke-VsDevCmd
}

# Win-X-I and Win-X-A will open in %userprofile% and %systemrootm%\system32 respectively
# instead set location to root of current drive
Set-Location \
