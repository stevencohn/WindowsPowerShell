
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
New-Alias vs Set-VsDevEnv
New-Alias push Push-Location
New-Alias pop Pop-Location

$0 = 'C:\Github\ClipboardViewer\bin\Debug\ClipboardViewer.exe'
if (Test-Path $0)
{
	function Start-ClipboardViewer
	{
		[CmdletBinding()]
		[Alias("cv")]
		param ($p1, $p2, $p3, $p4)
		& $0 $p1 $p2 $p3 $p4
	}
}

function Push-PSRoot
{
	[CmdletBinding()]
	[Alias("pushp")]
	param()
	Push-Location $PSScriptRoot
}

function Stop-Edge
{
	[CmdletBinding()]
	[Alias('stopedge')]
	param()
	taskkill /f /im msedge.exe
}

. $PSScriptRoot\Modules\Scripts\Set-OutDefaultOverride.ps1
Set-Alias ls Get-ChildItemColorized -Force -Option AllScope

# curl.exe is installed as a choco package to \system32; ensure no alias
Remove-Item alias:curl -ErrorAction SilentlyContinue

function Start-Wilma
{
	[CmdletBinding()]
	[Alias("wilma")]
	param()
	& 'C:\Tools\WiLMa\WinLayoutManager.exe'
}

New-Alias hx Get-HistoryEx
New-Alias Clear-History Clear-HistoryEx

# Docker helpers
New-Alias doc Remove-DockerTrash
New-Alias dos Show-Docker
New-Alias dow Start-DockerForWindows

# OK, Go!

# run vsdevcmd.bat if $env:vsdev is set; this is done by conemu task definition
if ($env:vsdev -eq '1') {
	Set-VsDevEnv
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

$cmd = (Get-CimInstance win32_process -filter ("ProcessID={0}" -f `
	(Get-CimInstance win32_process -filter "ProcessID=$PID").ParentProcessID)).CommandLine

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
	# invoke local folder-specific extensibility script
	. $pwd\PowerShell_profile.ps1
}

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradoxical.omp.json" | Invoke-Expression