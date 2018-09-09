
# override the prompt function
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


# Aliases

New-Alias ep Edit-PSProfile
New-Alias nu Invoke-NormalUser
New-Alias su Invoke-SuperUser
New-Alias vs Invoke-VsDevCmd
New-Alias cc Show-ColorizedContent

. $PSScriptRoot\Modules\Scripts\Set-OutDefaultOverride.ps1
Set-Alias ls Get-ChildItemColorized -Force -Option AllScope

function Start-Wilma { & 'C:\Program Files\Tools\WiLMa\WinLayoutManager.exe' }
New-Alias wilma Start-Wilma 

# Docker helpers
New-Alias doc Remove-DockerTrash
New-Alias dos Show-Docker
New-Alias dow Start-DockerForWindows

# OK, Go!

# run vsdevcmd.bat if $env:vsdev is set; this is done by conemu task definition
if ($env:vsdev -eq '1') {
	Invoke-VsDevCmd
}

# Chocolatey profile (added by Chocolatey installer)
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
	Import-Module "$ChocolateyProfile"
}

# Win-X-I and Win-X-A will open in %userprofile% and %systemrootm%\system32 respectively
# instead set location to a reasonable place so we force it to somewhere predictable.
# However we only want to do this when we open a new interactive shell window such
# as when opened from ConEmu, otherwise it will interfer with command-lines like Flat.bat
# modifying the current working directory when we don't want it to!

$cmd = (gwmi win32_process -filter ("ProcessID={0}" -f (gwmi win32_process -filter "ProcessID=$PID").ParentProcessID)).CommandLine
if ($cmd -notmatch 'cmd\.exe')
{
	if (Test-Path 'D:\Code') { Set-Location 'D:\Code'; }
	elseif (Test-Path 'D:\Development') { Set-Location 'D:\Development'; }
	elseif (Test-Path 'D:\Dev') { Set-Location 'D:\Dev'; }
	elseif (Test-Path 'C:\Development') { Set-Location 'C:\Development'; }
	elseif (Test-Path 'C:\Dev') { Set-Location 'C:\Dev'; }
	elseif (Test-Path 'D:\Everest') { Set-Location 'D:\Everest'; }
	elseif (Test-Path 'C:\Everest') { Set-Location 'C:\Everest'; }
	elseif (Test-Path 'C:\River') { Set-Location 'C:\River'; }
	else { Set-Location '\'; }
}
