
$env:PSElevated = Test-Elevated

# override the prompt function
function prompt {
	$saveCode = $LASTEXITCODE
	if ($env:PSElevated -eq $true) {
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
New-Alias push Push-Location
New-Alias pop Pop-Location

. $PSScriptRoot\Modules\Scripts\Set-OutDefaultOverride.ps1
Set-Alias ls Get-ChildItemColorized -Force -Option AllScope

# curl.exe is installed as a choco package to \system32
# so need to remove Invoke-WebRequest alias
Remove-Item alias:curl

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
	if (Test-Path 'C:\Github') { Set-Location 'C:\Github'; }
	elseif (Test-Path 'D:\scp') { Set-Location 'D:\scp'; }
	elseif (Test-Path 'C:\Code') { Set-Location 'C:\Code'; }
	elseif (Test-Path 'C:\River') { Set-Location 'C:\River'; }
	else { Set-Location '\'; }
}

if (Test-Path $pwd\PowerShell_profile.ps1)
{
	# enable custom profile setup for primary development area, e.g. command aliasing
	. $pwd\PowerShell_profile.ps1
}