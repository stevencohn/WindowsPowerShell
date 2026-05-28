# warning
if (!(Get-Command Test-Elevated -ea SilentlyContinue))
{
	Write-Host "*** Ensure $PSScriptRoot\Modules\Scripts is in your system env PATH" -ForegroundColor Red
	Write-Host "*** temporarily setting path" -ForegroundColor DarkGray
	$env:PATH += "$PSScriptRoot\Modules\Scripts"
}

$env:PSElevated = Test-Elevated

# --------------------------------------------------------------------------------------
# default prompt prior loading OhMyPosh

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

# --------------------------------------------------------------------------------------
# cmdlets

function Go-Profile
{
	[CmdletBinding()]
	[Alias('pushp', 'profile', 'goprofile', 'push-profile')]
	param()
	$p = [IO.Path]::GetDirectoryName($profile)
	Write-Host "... pushing $p" -fo DarkGray
	Push-Location $p
}

function Lock-RDP {
	# enable default screensaver and locking behavior
	[CmdletBinding()]
	[Alias("lock")]
	param()
    Set-RDP-Screensaver
}
function Unlock-RDP {
	# disable default screensaver and locking behavior for RDP sessions
	[CmdletBinding()]
	[Alias("unlock")]
	param()
	Set-RDP-Screensaver -Disable
}

function New-Console
{
	# start a new PS7 console window, rather than a Windows Terminal
	Start-Process conhost.exe -ArgumentList "`"$env:ProgramFiles\PowerShell\7\pwsh.exe`""
}

function Set-SubShellPrompt
{
	$env:POSH_THEME = "$env:POSH_THEMES_PATH\paradoxical-subshell.omp.json"
}

function Stop-Edge
{
	[CmdletBinding()]
	[Alias('stopedge')]
	param([switch]$WebView)
	taskkill /f /im msedge.exe
	if ($WebView) { taskkill /f /im msedgewebview2.exe }
}

function Start-OneMore
{
	[CmdletBinding()]
	[Alias("onemore")]
   	param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args)

    $exe = "C:\Github\OneMore\OneMore\bin\Debug\OneMoreCli.exe"
	if (!(Test-Path $exe)) { $exe = "C:\Github\stevencohn\OneMore\OneMore\bin\Debug\OneMoreCli.exe" }
	if (!(Test-Path $exe)) { Write-Host "OneMoreCli.exe not found!" -ForegroundColor Red; return }
    & $exe @Args
}

function Start-Wilma
{
	[CmdletBinding()]
	[Alias("wilma")]
	param()
	& 'C:\Tools\WiLMa\WinLayoutManager.exe'
}

# Command aliases...

. $PSScriptRoot\Modules\Scripts\Set-OutDefaultOverride.ps1
Set-Alias ls Get-ChildItemColorized -Force -Option AllScope

New-Alias Clear-History Clear-HistoryEx -ea SilentlyContinue
New-Alias ep Edit-PSProfile -ea SilentlyContinue
New-Alias hx Get-HistoryEx -ea SilentlyContinue
New-Alias pop Pop-Location -ea SilentlyContinue
New-Alias push Push-Location -ea SilentlyContinue
New-Alias rbh Remove-BrowserHijack -ea SilentlyContinue
New-Alias shell Set-SubShellPrompt -ea SilentlyContinue
New-Alias vs Set-VsDevEnv -ea SilentlyContinue

# Docker helpers
New-Alias doc Remove-DockerTrash -ea SilentlyContinue
New-Alias dos Show-Docker -ea SilentlyContinue
New-Alias dow Start-DockerForWindows -ea SilentlyContinue

# curl.exe is installed as a choco package to \system32; ensure no alias
Remove-Item alias:curl -ErrorAction SilentlyContinue

# --------------------------------------------------------------------------------------
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

# Win-X-I and Win-X-A will open in %userprofile% and %systemrootm%\system32 respectively.
# Instead, force location to somewhere predictable. But only do this when we open a new
# interactive shell, otherwise it will interfere with command-lines like Flat.bat and modifying
# the current working directory when we don't want it to!

$cmd = (Get-CimInstance win32_process -filter ("ProcessID={0}" -f `
	(Get-CimInstance win32_process -filter "ProcessID=$PID").ParentProcessID)).CommandLine

if ($cmd -notmatch 'cmd\.exe')
{
	if (Test-Path 'C:\Github') { Set-Location 'C:\Github'; }
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

# enable predictive intellisense listview
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
