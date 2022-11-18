
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
New-Alias vs Invoke-VsDevCmd
New-Alias push Push-Location
New-Alias pop Pop-Location

function Push-PSRoot { Push-Location $PSScriptRoot }
New-Alias pushp Push-PSRoot

. $PSScriptRoot\Modules\Scripts\Set-OutDefaultOverride.ps1
Set-Alias ls Get-ChildItemColorized -Force -Option AllScope

# curl.exe is installed as a choco package to \system32; ensure no alias
Remove-Item alias:curl -ErrorAction SilentlyContinue

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

# Win-X-I and Win-X-A will open in %userprofile% and %systemrootm%\system32 respectively.
# Instead, force location to somewhere predictable. But only do this when we open a new
# interactive shell, otherwise it will interfere with command-lines like Flat.bat and modifying
# the current working directory when we don't want it to!

$cmd = (Get-WmiObject win32_process -filter ("ProcessID={0}" -f `
	(Get-WmiObject win32_process -filter "ProcessID=$PID").ParentProcessID)).CommandLine

if ($cmd -notmatch 'cmd\.exe')
{
	if (Test-Path 'D:\scp') { Set-Location 'D:\scp'; }
	elseif (Test-Path 'D:\Github') { Set-Location 'D:\Github'; }
	elseif (Test-Path 'C:\Github') { Set-Location 'C:\Github'; }
	elseif (Test-Path 'C:\Code') { Set-Location 'C:\Code'; }
	elseif (Test-Path 'C:\River') { Set-Location 'C:\River'; }
	else { Set-Location '\'; }
}

if (Test-Path $pwd\PowerShell_profile.ps1)
{
	# enable custom profile setup for primary development area, e.g. command aliasing
	. $pwd\PowerShell_profile.ps1
}