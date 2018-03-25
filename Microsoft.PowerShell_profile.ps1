
function Test-Elevated {
	$user = [Security.Principal.WindowsIdentity]::GetCurrent();
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

<#
.SYNOPSIS
Set the prompt to a colorized string customized by elevation
#>
function prompt {
	$saveCode = $LASTEXITCODE
	if (Test-Elevated) {
		Write-Host "PS " -NoNewline -ForegroundColor Red
		Write-Host $pwd -NoNewline -ForegroundColor Blue
	}
	else {
		Write-Host "PS $pwd" -NoNewline -ForegroundColor Blue
	}

	$global:LASTEXITCODE = $saveCode
	return "> "
}


<#
.SYNOPSIS
Open a new command prompt in elevated mode - alias 'su'
#>
function Invoke-SuperUser { conemu /single /cmd -cur_console:an powershell }
New-Alias su Invoke-SuperUser


# invoke the Visual Studio environment batch script - alias 'vs'
function Invoke-VsDevCmd {
	Push-Location "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Enterprise\Common7\Tools"

	cmd /c "VsDevCmd.bat&set" | ForEach-Object `
 {
		if ($_ -match "=") {
			$v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
		}
	}

	Pop-Location
}
New-Alias vs Invoke-VsDevCmd


# run vsdevcmd.bat if $env:vsdev is set; this is done by conemu task definition
if ($env:vsdev -eq '1') {
	Invoke-VsDevCmd
}


#***************************************************************************************
# Docker helpers
#***************************************************************************************

<#
.SYNOPSIS
Prune unused docker containers and dangling images.
#>
function Invoke-DockerClean {
	if (!(New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole( `
				[Security.Principal.WindowsBuiltinRole]::Administrator)) {
		Write-Host 'Must be an administrator to run this command'
		return
	}

	Write-Host
	$trash = $(docker ps -a -q)
	if ($trash -ne $null) {
		Write-Host ('Removing {0} stopped containers...' -f $trash.Count) -ForegroundColor DarkYellow
		docker container prune
	}
	else {
		Write-Host "No stopped containers" -ForegroundColor DarkYellow
	}

	Write-Host
	$trash = $(docker images --filter "dangling=true" -q --no-trunc)
	if ($trash -ne $null) {
		Write-Host ('Removing {0} dangling images...' -f $trash.Count) -ForegroundColor DarkYellow
		docker rmi $trash
	}
	else {
		Write-Host "No dangling images" -ForegroundColor DarkYellow
	}

	Write-Host
}
New-Alias doclean Invoke-DockerClean


<#
.SYNOPSIS
Show containers and images in a single command.
#>
function Invoke-DockerShow {
	if (!(New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole( `
				[Security.Principal.WindowsBuiltinRole]::Administrator)) {
		Write-Host 'Must be an administrator to run this command'
		return
	}

	Write-Host
	Write-Host 'Containers...' -ForegroundColor DarkYellow
	docker ps -a
	Write-Host
	Write-Host 'Images...' -ForegroundColor DarkYellow
	docker images
	Write-Host
}
New-Alias doshow Invoke-DockerShow


#***************************************************************************************
# Get-ColorDir (lc)
#***************************************************************************************

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
	param ($dir)
	$bytes = 0
	$count = 0

	Get-Childitem $dir | Foreach-Object `
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
		Write-Host ("" + $bytes + " bytes") -ForegroundColor "White" -NoNewLine
	}
	Write-Host " in $count files"
}

function Get-ColorDir {
	param ($dir)
	Get-Childitem $dir
	Get-DirSize $dir
}

Remove-Item alias:dir
Remove-Item alias:ls
Set-Alias dir Get-ColorDir
Set-Alias ls Get-ColorDir

New-Alias cc Show-ColorizedContent


# Win-X-I and Win-X-A will open in %userprofile% and %systemrootm%\system32 respectively
# instead set location to root of current drive
Set-Location \
