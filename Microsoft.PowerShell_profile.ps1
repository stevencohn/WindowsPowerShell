
# override the prompt function
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


# Aliases

New-Alias ep Invoke-EditProfile
New-Alias su Invoke-SuperUser
New-Alias vs Invoke-VsDevCmd
New-Alias cc Show-ColorizedContent

. $PSScriptRoot\Modules\Scripts\Set-OutDefaultOverride.ps1
Set-Alias ls Get-ChildItemColorized -Force -Option AllScope

function Invoke-Wilma { & 'C:\Program Files\Tools\WiLMa\WinLayoutManager.exe' }
New-Alias wilma Invoke-Wilma 

# Docker helpers
New-Alias doc Invoke-DockerClean
New-Alias dos Invoke-DockerShow

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
# instead set location to a reasonable place
if (Test-Path 'D:\Code') { Set-Location 'D:\Code'; }
elseif (Test-Path 'D:\Development') { Set-Location 'D:\Development'; }
elseif (Test-Path 'D:\Dev') { Set-Location 'D:\Dev'; }
elseif (Test-Path 'C:\Development') { Set-Location 'C:\Development'; }
elseif (Test-Path 'C:\Dev') { Set-Location 'C:\Dev'; }
else { Set-Location '\'; }
