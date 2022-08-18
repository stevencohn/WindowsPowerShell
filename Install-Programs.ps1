<#
.SYNOPSIS
Automates the installation of applications, development tools, and other utilities.

.PARAMETER Command
Invoke a single command from this script; default is to run all.

.PARAMETER DeveloperTools
Installs development tools specific to my needs.

.PARAMETER Extras
Installs extra apps and utilities.

.PARAMETER ListCommands
Show a list of all available commands.

.DESCRIPTION
Highly recommed that you first run all Windows updates and then run
Initialize-Machine.ps1 before running this script.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
	[string] $command,
	[switch] $ListCommands,
	[switch] $DeveloperTools,
	[switch] $Extras,
	[switch] $Continuation
)

Begin
{
	. $PSScriptRoot\common.ps1

	$tools = 'C:\tools'
	$script:reminders = @(@())


	function GetCommandList
	{
		Get-ChildItem function:\ | Where HelpUri -match 'cmd' | select -expand Name | sort
	}


	function InvokeCommand
	{
		param($command)
		$fn = Get-ChildItem function:\ | where Name -eq $command
		if ($fn -and ($fn.HelpUri -eq 'cmd'))
		{
			Highlight "... invoking command $($fn.Name)"
			Invoke-Expression $fn.Name
		}
		else
		{
			Write-Host "$command is not a recognized command" -ForegroundColor Yellow
			Write-Host 'Use -List argument to see all commands' -ForegroundColor DarkYellow
		}
	}


	#==============================================================================================
	# BASE

	function InstallDotNetRuntime
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		if (((Get-Command dotnet -ErrorAction:SilentlyContinue) -eq $null) -or `
			((dotnet --list-runtimes | where { $_ -match '6\.0\.' }).Count -eq 0))
		{
			HighTitle '.NET 6.0 Runtime'
			choco install -y dotnet

			# patch Process path until shell is restarted
			$env:PATH = (($env:PATH -split ';') -join ';') + ";C:\Program Files\dotnet"
		}
		else
		{
			WriteOK '.NET 6.0 Runtime already installed'
		}
	}

	function InstallDotNetFramework
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		# .NET Framework is required by many apps
		if ((Get-WindowsOptionalFeature -Online -FeatureName 'NetFx4' | `
			where { $_.State -eq 'Enabled'}).Count -eq 0)
		{
			HighTitle '.NET Framework NetFx4'

			# don't restart but will after .NET (Core) is installed
			Enable-WindowsOptionalFeature -Online -FeatureName 'NetFx4' -NoRestart

			RebootWithContinuation
		}
		else
		{
			WriteOK '.NET Framework NetFx4 already installed'
		}
	}


	function InstallBareTail
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		$target = "$tools\BareTail"
		if (!(Test-Path $target))
		{
			#https://baremetalsoft.com/baretail/download.php?p=m
			HighTitle 'BareTail'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null
			DownloadBootstrap 'baretail.zip' $target
		}
		else
		{
			WriteOK 'BareTail already installed'
		}
	}


	function InstallGreenshot
	{
		[CmdletBinding(HelpURI = 'cmd')] param()
		if (UnChocolatized 'greenshot')
		{
			# Get-AppxPackage *Microsoft.ScreenSketch* -AllUsers | Remove-AppxPackage -AllUsers
			## disable the Win-Shift-S hotkey for ScreenSnipper
			# $0 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
			# New-ItemProperty -Path $0 -Name 'DisabledHotkeys' -Value 'S' -ErrorAction:SilentlyContinue

			Highlight 'A warning dialog will appear about hotkeys - ignore it' 'Cyan'
			Chocolatize 'greenshot'
		}
		else
		{
			WriteOK 'Greenshot already installed'
		}
	}


	function InstallMacrium
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		if (!(Test-Path "$env:ProgramFiles\Macrium\Reflect"))
		{
			$target = "$tools\Reflect"
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null

			# Do NOT use chocolatey to install reflect-free because that includes a version of
			# autohotkey that Cortex antivirus detects as malware but the base installer does not

			DownloadBootstrap 'ReflectDLHF.zip' $target

			$reminder = 'Macrium Reflect', `
				' 0. Run the Macrium Reflect Free installer after VS is installed', `
				" 1. The installer is here: $target", `
				' 2. Choose Free version, no registration is necessary'

			$script:reminders += ,$reminder
			Highlight $reminder 'Cyan'

			# This runs the downloader and leaves the dialog visible!
			#& $tools\ReflectDL.exe
		}
		else
		{
			WriteOK 'Macrium installer already installed'
		}
	}


	function InstallNotepadPP
	{
		[CmdletBinding(HelpURI = 'cmd')] param()
		if (UnChocolatized 'notepadplusplus')
		{
			Chocolatize 'notepadplusplus'
			Chocolatize 'npppluginmanager'

			$themes = "$env:ProgramFiles\notepad++\themes"
			New-Item $themes -ItemType Directory -Force
			Copy-Item "$home\Documents\WindowsPowerShell\Themes\Dark Selenitic npp.xml" "$themes\Dark Selenitic.xml"

			$0 = "$($env:APPDATA)\Notepad++\userDefineLangs"
			if (!(Test-Path $0))
			{
				New-Item $0 -ItemType Directory -Force -Confirm:$false
			}
			# includes a dark-selenitic Markdown lang theme
			DownloadBootstrap 'npp-userDefineLangs.zip' $0

			<# To do this manually, in elevated CMD prompt:
			reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" `
			  /v "Debugger" /t REG_SZ /d "\"%ProgramFiles%\Notepad++\notepad++.exe\" -notepadStyleCmdline -z" /f
			#>

			# replace notepad.exe
			HighTitle 'Replacing notepad with notepad++'
			$0 = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe'
			$exe = (Get-Command 'notepad++').Source
			$cmd = """$exe"" -notepadStyleCmdline -z"
			if (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
			New-ItemProperty -Path $0 -Name 'Debugger' -Value $cmd -Force | Out-Null

			# add Open with Notepad to Explorer context menu
			Push-Location -LiteralPath 'HKLM:\SOFTWARE\Classes\*\shell'
			New-Item -Path 'Open with Notepad\command' -Force | New-ItemProperty -Name '(Default)' -Value 'notepad "%1"'
			Pop-Location
		}
		else
		{
			WriteOK 'Notepad++ already installed'
		}
	}


	function InstallSysInternals
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		$target = "$tools\SysInternals"
		if (!(Test-Path $target))
		{
			HighTitle 'SysInternals'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null
			DownloadBootstrap 'SysInternals.zip' $target
		}
		else
		{
			WriteOK 'SysInternals already installed'
		}

		$target = "$tools\volumouse"
		if (!(Test-Path $target))
		{
			HighTitle 'Volumouse'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null
			DownloadBootstrap 'volumouse-x64.zip' $target

			# add to Startup
			$0 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
			$1 = '"C:\tools\volumouse\volumouse.exe" /nodlg'
			New-ItemProperty -Path $0 -Name '$Volumouse$' -Value $1 -ErrorAction:SilentlyContinue

			& $target\volumouse.exe
		}
		else
		{
			WriteOK 'Volumouse already installed'
		}
	}


	function InstallTerminal
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		<#
		UPGRADE NOTE - Can upgrade with these steps:
			1. choco update microsoft-window-terminal
			2. New-RunasShortcut C:\Tools\wt.lnk "....\wt.exe" (path built as below)
			3. Manually pin that wt.lnk shortcut to taskbar
		#>

		## winget install --id=Microsoft.WindowsTerminal -e --source winget

		$parentId = (gwmi win32_process -Filter "processid='$pid'").parentprocessid
		if ((gwmi win32_process -Filter "processid='$parentId'").Name -eq 'WindowsTerminal.exe')
		{
			Write-Host 'Cannot install microsoft-windows-terminal from a Windows Terminal console' -ForegroundColor Red
			return
		}

		Chocolatize 'microsoft-windows-terminal'

		ConfigureTerminalSettings

		if (!(IsWindows11))
		{
			ConfigureTerminalShortcut
		}

		$reminder = 'Windows Terminal', `
			" 0. Pin C:\Tools\wt.lnk to Taskbar", `
			' 1. initialPosition can be set globally in settings.json ("x,y" value)'

		$script:reminders += ,$reminder
		Highlight $reminder 'Cyan'
	}


	function ConfigureTerminalSettings
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		# customize settings... for Terminal 1.8.1444.0, 1.9.1942.0

		$appName = 'Microsoft.WindowsTerminal'
		$appKey = '8wekyb3d8bbwe'

		$0 = "$($env:LOCALAPPDATA)\Packages\$appName`_$appKey\LocalState\settings.json"
		if (!(Test-Path $0))
		{
			# when Terminal is first installed, no settings file exists so download default
			$zip = ((choco list -l -r -e microsoft-windows-terminal) -replace '\|','_') + '.json.zip'
			Write-Host "Downloading default Terminal settings file $zip" -ForegroundColor DarkGray
			DownloadBootstrap $zip (Split-Path $0)
		}

		# must remove comments to feed into ConvertFrom-Json
		$settings = (Get-Content $0) -replace '^\s*//.*' | ConvertFrom-Json

		$settings.initialCols = 160
		$settings.initialRows = 85
		$settings.initialPosition = '200,25'

		$scheme = New-Object -TypeName PsObject -Property @{
			background = '#080808'
			black = '#0C0C0C'
			blue = '#3465A4'
			brightBlack = '#767676'
			brightBlue = '#729FCF'
			brightCyan = '#34E2E2'
			brightGreen = '#8AE234'
			brightPurple = '#AD7FA8'
			brightRed = '#EF2929'
			brightWhite = '#F2F2F2'
			brightYellow = '#FCE94F'
			cursorColor = '#FFFFFF'
			cyan = '#06989A'
			foreground = '#CCCCCC'
			green = '#4E9A06'
			name = 'DarkSelenitic'
			purple = '#75507B'
			red = '#CC0000'
			selectionBackground = '#FFFFFF'
			white = '#CCCCCC'
			yellow = '#C4A000'
		}

		$schemes = [Collections.Generic.List[Object]]($settings.schemes)
		$index = $schemes.FindIndex({ $args[0].name -eq 'DarkSelenitic' })
		if ($index -lt 0) {
			$settings.schemes += $scheme
		} else {
			$settings.schemes[$index] = $scheme
		}

		$profile = $settings.profiles.list | ? { $_.commandline -and (Split-Path $_.commandline -Leaf) -eq 'powershell.exe' }
		if ($profile)
		{
			$profile.antialiasingMode = 'aliased'
			$profile.colorScheme = 'DarkSelenitic'
			$profile.cursorShape = 'underscore'
			$profile.fontFace = 'Lucida Console'
			$profile.fontSize = 9

			$png = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'architecture.png'
			if (!(Test-Path $png))
			{
				$png = "$($env:APPDATA)\ConEmu\architecture.png"
			}
			if (Test-Path $png)
			{
				if ($profile.backgroundImage) {
					$profile.backgroundImage = $png
				} else {
					$profile | Add-Member -MemberType NoteProperty -Name 'backgroundImage' -Value $png
				}

				if ($profile.backgroundImageOpacity) {
					$profile.backgroundImageOpacity = 0.03
				} else {
					$profile | Add-Member -MemberType NoteProperty -Name 'backgroundImageOpacity' -Value 0.03
				}
			}
		}

		# use -Depth to retain fidelity in complex objects without converting
		# object properties to key/value collections
		ConvertTo-Json $settings -Depth 100 | Out-File $0 -Encoding Utf8
	}


	function ConfigureTerminalShortcut
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		# Create shortcut wt.lnk file; this then needs to be manually pinned to taskbar
		$appName = 'Microsoft.WindowsTerminal'
		$appKey = '8wekyb3d8bbwe'
		$version = (choco list -l -r -e microsoft-windows-terminal).Split('|')[1]
		New-RunasShortcut C:\Tools\wt.lnk "$($env:ProgramFiles)\WindowsApps\$appName`_$version`_x64__$appKey\wt.exe"
	}


	function HyperVInstalled
	{
		((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -eq 'Enabled')
	}

	function DisableCFG
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		if (!(HyperVInstalled))
		{
			Highlight '... Cannot disable CFG until Hyper-V is installed'
			return
		}

		<#
		Following is from online to troubleshoot startup errors:
		1, Open "Window Security"
		2, Open "App & Browser control"
		3, Click "Exploit protection settings" at the bottom
		4, Switch to "Program settings" tab
		5, Locate "C:\WINDOWS\System32\vmcompute.exe" in the list and expand it
		6, Click "Edit"
		7, Scroll down to "Code flow guard (CFG)" and uncheck "Override system settings"
		8, Start vmcompute from powershell "net start vmcompute"
		#>

		$0 = 'C:\WINDOWS\System32\vmcompute.exe'
		if ((Get-ProcessMitigation -Name $0).CFG.Enable -eq 'ON')
		{
			# disable Code Flow Guard (CFG) for vmcompute service
			Set-ProcessMitigation -Name $0 -Disable CFG
			Set-ProcessMitigation -Name $0 -Disable StrictCFG
			# restart service
			net stop vmcompute
			net start vmcompute
		}
	}

	#==============================================================================================
	# DEVELOPER

	function InstallDotNetSDK
	{
		# .NET SDK
		if ((dotnet --list-sdks | where { $_ -match '6\.0\.' }).Count -eq 0)
		{
			HighTitle '.NET 6.0 SDK'
			choco install -y dotnet-sdk
		}
		else
		{
			WriteOK '.NET 6.0 SDK already installed'
		}
	}

	function InstallNodeJs
	{
		[CmdletBinding(HelpURI = 'cmd')] param()
		if ((Get-Command node -ErrorAction:SilentlyContinue) -eq $null)
		{
			HighTitle 'nodejs'
			#choco install -y nodejs --version 12.16.3
			choco install -y nodejs
			# update session PATH so we can continue
			$npmpath = [Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';' | ? { $_ -match 'nodejs' }
			$env:PATH = (($env:PATH -split ';') -join ';') + ";$npmpath"
		}
		else
		{
			WriteOK 'Nodejs already installed'
		}
	}


	function InstallAngular
	{
		[CmdletBinding(HelpURI = 'cmd')] param()
		if ((Get-Command ng -ErrorAction:SilentlyContinue) -eq $null)
		{
			HighTitle 'angular'
			npm install -g @angular/cli@latest
			npm install -g npm-check-updates
			npm install -g local-web-server

			# patch Process path until shell is restarted
			$env:PATH = (($env:PATH -split ';') -join ';') + ";$($env:APPDATA)\npm"
		}
		else
		{
			WriteOK 'Angular already installed'
		}
	}
	

	function InstallAWSCLI
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		if ((Get-Command aws -ErrorAction:SilentlyContinue) -ne $null)
		{
			return
		}

		$0 = 'C:\Program Files\Amazon\AWSCLIV2'
		if (!(Test-Path $0))
		{
			# ensure V2.x of awscli is available on chocolatey.org
			if ((choco list awscli -limit-output | select-string 'awscli\|2' | measure).count -gt 0)
			{
				Chocolatize 'awscli'

				# alternatively...
				#msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
			}
			else
			{
				HighTitle 'awscli (direct)'

				# download package directly and install
				[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
				$msi = "$env:TEMP\awscliv2.msi"
				$progressPreference = 'silentlyContinue'
				Invoke-WebRequest 'https://awscli.amazonaws.com/AWSCLIV2.msi' -OutFile $msi
				$progressPreference = 'Continue'
				if (Test-Path $msi)
				{
					& $msi /quiet
				}
			}
		}

		# path will be added to Machine space when installed so
		# fix Process path so we can continue to install add-ons
		if ((Get-Command aws -ErrorAction:SilentlyContinue) -eq $null)
		{
			$env:PATH = (($env:PATH -split ';') -join ';') + ";$0"
		}

		if ((Get-Command aws -ErrorAction:SilentlyContinue) -ne $null)
		{
			Highlight 'aws command verified' 'Cyan'
		}
	}


	function InstallDockerDesktop
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		if (!(HyperVInstalled))
		{
			Highlight '... Hyper-V must be installed before Docker Desktop'
			return
		}

		if (UnChocolatized 'docker-desktop')
		{
			Chocolatize 'docker-desktop'

			$reminder = 'Docker Desktop', `
				' 0. Restart console window to get updated PATH', `
				' 1. Unsecure repos must be added manually'

			$reminders += ,$reminder
			Highlight $reminder 'Cyan'
		}
		else
		{
			WriteOK 'Docker Desktop already installed'
		}
	}


	function InstallS3Browser
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		if (UnChocolatized 's3browser')
		{
			Chocolatize 's3browser'
		}
		else
		{
			WriteOK 's3browser already installed'
		}
	}


	#==============================================================================================
	# EXTRAS

	function InstallDateInTray
	{
		[CmdletBinding(HelpURI = 'cmd')] param()

		$target = "$tools\DateInTray"
		if (!(Test-Path $target))
		{
			#https://softpedia-secure-download.com/dl/ba833328e1e20d7848a5498418cb5796/5dfe1db7/100016805/software/os_enhance/DITSetup.exe

			HighTitle 'DateInTray'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null

			DownloadBootstrap 'DateInTray.zip' $target

			# add to Startup
			$0 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
			$hex = [byte[]](0x20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			New-ItemProperty -Path $0 -Name 'DateInTray' -PropertyType Binary -Value $hex -ErrorAction:SilentlyContinue
			$0 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
			New-ItemProperty -Path $0 -Name 'DateInTray' -Value "$target\DateInTray.exe" -ErrorAction:SilentlyContinue

			& $target\DateInTray.exe
		}
		else
		{
			WriteOK 'DateInTray already installed'
		}
	}

	
	function InstallGreenfish
	{
		[CmdletBinding(HelpURI='cmd')] param()

		# http://greenfishsoftware.org/gfie.php

		$0 = 'C:\Program Files (x86)\Greenfish Icon Editor Pro 3.6\gfie.exe'
		if (!(Test-Path $0))
		{
			HighTitle 'Greenfish'

			# download the installer
			$name = 'greenfish_icon_editor_pro_setup_3.6'
			DownloadBootstrap "$name`.zip" $env:TEMP

			# run the installer
			& "$($env:TEMP)\$name`.exe" /verysilent
		}
		else
		{
			WriteOK 'Greenfish already installed'
		}
	}


	function InstallWiLMa
	{
		[CmdletBinding(HelpURI = 'cmd|extra')] param()

		$target = "$tools\WiLMa"
		if (!(Test-Path $target))
		{
			HighTitle 'WiLMa'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null

			# http://www.stefandidak.com/wilma/winlayoutmanager.zip
			DownloadBootstrap 'winlayoutmanager.zip' $target

			# Register WindowsLayoutManager sheduled task to run as admin
			$trigger = New-ScheduledTaskTrigger -AtLogOn
			$action = New-ScheduledTaskAction -Execute "$target\WinLayoutManager.exe"
			$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
			Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "WiLMa" -Principal $principal

			Start-Process $target\WinLayoutManager.exe -Verb runas
		}
		else
		{
			WriteOK 'WiLMa already installed'
		}
	}


	function InstallWmiExplorer
	{
		[CmdletBinding(HelpURI = 'cmd|extra')] param()

		$target = "$tools\WmiExplorer"
		if (!(Test-Path $target))
		{
			HighTitle 'WmiExplorer'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null

			DownloadBootstrap 'wmiexplorer.zip' $target
		}
		else
		{
			WriteOK 'WmiExplorer already installed'
		}
	}
}
Process
{
	if ($ListCommands)
	{
		GetCommandList
		return
	}

	if (!(IsElevated))
	{
		return
	}

	# prerequisites... should have been installed by Initialize-Machine

	InstallChocolatey
	InstallCurl
	InstallGit

	if ($command)
	{
		InvokeCommand $command
		return
	}

	# BASE...

	InstallDotNetRuntime
	InstallDotNetFramework

	if ($Continuation)
	{
		CleanupContinuation

		InstallBareTail
		InstallGreenshot
		InstallMacrium
		InstallNotepadPP
		InstallSysInternals

		if (!(IsWindows11)) {
			InstallTerminal
		}

		DisableCFG

		Chocolatize '7Zip'
		Chocolatize 'adobereader'
		Chocolatize 'dotnet'
		Chocolatize 'greenshot'
		Chocolatize 'mRemoteNG'
		Chocolatize 'procexp'
		Chocolatize 'procmon'
		Chocolatize 'sharpkeys'
	}

	# DEVELOPER...

	if ($DeveloperTools)
	{
		InstallDotNetSDK
		InstallNodeJs
		InstallAngular
		InstallAWSCli
		InstallDockerDesktop
		InstallS3Browser

		Chocolatize 'k9s'
		Chocolatize 'linqpad'
		Chocolatize 'nuget.commandline'
		Chocolatize 'robo3t'
	}

	# EXTRAS...

	if ($Extras)
	{
		if (!(IsWindows11)) {
			InstallDateInTray
		}

		InstallGreenfish
		InstallWilMa
		InstallWmiExplorer

		Chocolatize 'audacity'  # audio editor
		#Chocolatize 'dopamine'  # music player
		Chocolatize 'licecap'
		Chocolatize 'paint.net'
		Chocolatize 'treesizefree'
		Chocolatize 'vlc'
	}

	# done...

	$reminder = 'Consider these manually installed apps:', `
		' - BeyondCompare (there is a choco package but not for 4.0)', `
		' - OneMore OneNote add-in (https://github.com/stevencohn/OneMore/releases)'

	$script:reminders += ,$reminder

	$line = New-Object String('*',80)
	Write-Host
	Write-Host $line -ForegroundColor Cyan
	Write-Host ' Reminders ...' -ForegroundColor Cyan
	Write-Host $line -ForegroundColor Cyan
	Write-Host

	$script:reminders | % { $_ | % { Write-Host $_ -ForegroundColor Cyan }; Write-Host }

	WriteOK '... Initialization compelete'
	Read-Host '... Press Enter to finish'
}
