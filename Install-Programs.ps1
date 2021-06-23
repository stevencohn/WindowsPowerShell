<#
.SYNOPSIS
Automates the installation of applications, development tools, and other utilities.

.PARAMETER Command
Invoke a single command from this script; default is to run all.

.PARAMETER AccessKey
Optional, sets the AWS access key in configuration 

.PARAMETER Enterprise
Install Visual Studio Enterprise; default is to install Professional

.PARAMETER Extras
Installs more than most developers would need or want; this is my personalization.

.PARAMETER ListCommands
Show a list of all available commands.

.PARAMETER SecretKey
Optional, sets the AWS secret key in configuration

.DESCRIPTION
Recommend running after Initialize-Machine.ps1 and all Windows updates.
Tested on Windows 10 update 1909.

.EXAMPLE
.\Install-Programs.ps1 -List
.\Install-Programs.ps1 -AccessKey <key> -SecretKey <key> -Extras -Enterprise
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'go')]

param (
	[Parameter(ParameterSetName = 'go', Position = 0)] $command,
	[Parameter(ParameterSetName = 'go', Position = 1)] [string] $AccessKey,
	[Parameter(ParameterSetName = 'go', Position = 2)] [string] $SecretKey,
	[Parameter(ParameterSetName = 'list')] [switch] $ListCommands,
	[switch] $Extras,
	[switch] $Enterprise,
	[Parameter(ParameterSetName = 'continue')] [switch] $Continue
)

Begin
{
	$stage = 0
	$stagefile = (Join-Path $env:LOCALAPPDATA 'install-programs.stage')
	$ContinuationName = 'Install-Programs-Continuation'
	$tools = 'C:\tools'
	$script:reminders = @(@())


	function TestElevated
	{
		$ok = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()`
			).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

		if (!$ok)
		{
			Write-Host
			Write-Host '... This script must be run from an elevated console' -ForegroundColor Yellow
			Write-Host '... Open an administrative PowerShell window and run again' -ForegroundColor Yellow
		}

		return $ok
	}


	function GetCommandList
	{
		Get-ChildItem function:\ | Where HelpUri -eq 'manualcmd' | select -expand Name | sort
	}


	function InvokeCommand
	{
		param($command)
		$fn = Get-ChildItem function:\ | where Name -eq $command
		if ($fn -and ($fn.HelpUri -eq 'manualcmd'))
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


	function UnChocolatized
	{
		param($name)
		((choco list -l $name | Select-string "$name ").count -eq 0)
	}


	function Chocolatize
	{
		param($name)
		if (UnChocolatized $name)
		{
			HighTitle $name
			choco install -y $name
		}
		else
		{
			Write-Host "$name already installed by chocolatey" -ForegroundColor Green
		}
	}


	function TestAwsConfiguration
	{
		$ok = (Test-Path $home\.aws\config) -and (Test-Path $home\.aws\credentials)

		if (!$ok)
		{
			Write-Host
			Write-Host '... AWS credentials are required' -ForegroundColor Yellow
			Write-Host '... Specify the -AccessKey and -SecretKey parameters' -ForegroundColor Yellow
		}

		return $ok
	}


	function ConfigureAws
	{
		param($access, $secret)

		if (!(Test-Path $home\.aws))
		{
			New-Item $home\.aws -ItemType Directory -Force -Confirm:$false | Out-Null
		}

		'[default]', `
			'region = us-east-1', `
			'output = json' `
			| Out-File $home\.aws\config -Encoding ascii -Force -Confirm:$false

		'[default]', `
			"aws_access_key_id = $access", `
			"aws_secret_access_key = $secret" `
			| Out-File $home\.aws\credentials -Encoding ascii -Force -Confirm:$false

		Write-Verbose 'AWS configured; no need to specify access/secret keys from now on'
	}


	function Download
	{
		param($uri, $target)
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12';
		Invoke-WebRequest -Uri $uri -OutFile $target
	}


	function DownloadBootstrap
	{
		# source=filename, target=folder
		param($source, $target)

		$zip = Join-Path $target $source

		if ($env:GITHUB_TOKEN)
		{
			curl -s -H "Authorization: token $($env:GITHUB_TOKEN)" `
				-H 'Accept: application/vnd.github.v3.raw' `
				-o $zip -L "https://api.github.com/repos/stevencohn/bootstraps/contents/$source`?ref=main"
		}
		else
		{
			curl -s "https://raw.githubusercontent.com/stevencohn/bootstraps/main/$source" -o $zip
		}

		Expand-Archive $zip -DestinationPath $target -Force | Out-Null
		Remove-Item $zip -Force -Confirm:$false
	}


	function Highlight
	{
		param($text = '', $color = 'Yellow')
		$text | Write-Host -ForegroundColor Black -BackgroundColor $color
	}


	function HighTitle
	{
		param($title)
		Highlight '', "---- Installing $title ---------------------------"
	}


	# Stage 0 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	function InstallHyperV
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		# ensure Hyper-V
		if (!(HyperVInstalled))
		{
			$progressPreference = 'silentlyContinue'
			$0 = (Get-ComputerInfo).WindowsProductName
			$progressPreference = 'Continue'

			if ($0.Contains('Home'))
			{
				Write-Warning "Cannot install Hyper-V on $0"
				return
			}

			HighTitle 'Hyper-V'
			Highlight '', '... Reboot will be required after installing Hyper-V', `
				'... This script will continue automagically after the reboot' 'Cyan'

			Set-Content $stagefile '1' -Force
			$script:stage = 1

			# prep a logon continuation task
			$exarg = '-Continue'
			if ($Extras) { $exarg = "$exarg -Extras" }
			if ($Enterprise) { $exarg = "$exarg -Enterprise" }

			$trigger = New-ScheduledTaskTrigger -AtLogOn;
			# note here that the -Command arg string must be wrapped with double-quotes
			$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-Command ""$PSCommandPath $exarg"""
			$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest;
			Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $ContinuationName -Principal $principal | Out-Null

			Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart
			Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

			Restart-Computer -Force
		}
		else
		{
			$script:stage = 1
			Write-Host 'Hyper-V already installed' -ForegroundColor Green
		}
	}

	function HyperVInstalled
	{
		((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -eq 'Enabled')
	}


	function InstallNetFx
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		# .NET Framework 3.5 is required by many apps
		if ((Get-WindowsOptionalFeature -Online -FeatureName 'NetFx3' | ? { $_.State -eq 'Enabled'}).Count -eq 0)
		{
			HighTitle '.NET Framework 3.5'

			# don't restart but will after Hyper-V finishes stage 0
			Enable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -NoRestart
		}
		else
		{
			Write-Host '.NET Framework 3.5 already installed' -ForegroundColor Green
		}

		if (((Get-Command dotnet -ErrorAction:SilentlyContinue) -eq $null) -or `
			((dotnet --list-sdks | ? { $_ -match '^5.0.' }).Count -eq 0))
		{
			# currently required for our apps, may change
			HighTitle '.NET 5.0'
			choco install -y dotnet
		}
		else
		{
			Write-Host '.NET 5.0 already installed' -ForegroundColor Green
		}
	}


	# Stage 1 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	function DisableCFG
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		# customize Hyper-V host file locations
		Set-VMHost -VirtualMachinePath 'C:\VMs' -VirtualHardDiskPath 'C:\VMs\Disks'

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


	function InstallAngular
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		if ((Get-Command ng -ErrorAction:SilentlyContinue) -eq $null)
		{
			HighTitle 'angular'
			npm install -g @angular/cli@9.1.6
			npm install -g npm-check-updates
			npm install -g local-web-server
		}
		else
		{
			Write-Host 'Angular already installed' -ForegroundColor Green
		}
	}


	function InstallAWSCLI
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

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


	function InstallBareTail
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

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
			Write-Host 'BareTail already installed' -ForegroundColor Green
		}
	}


	function InstallDockerDesktop
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		if (!(HyperVInstalled))
		{
			Highlight '... Installing Hyper-V prerequisite before Docker Desktop'
			InstallHyperV
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
			Write-Host 'Docker Desktop already installed' -ForegroundColor Green
		}
	}


	function InstallGreenfish
	{
		[CmdletBinding(HelpURI='manualcmd')] param()

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
			Write-Host 'Greenfish already installed' -ForegroundColor Green
		}
	}


	function InstallGreenshot
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
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
			Write-Host 'Greenshot already installed' -ForegroundColor Green
		}
	}


	function InstallMacrium
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

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
			Write-Host 'Macrium installer already installed' -ForegroundColor Green
		}
	}


	function InstallNodeJs
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		if ((Get-Command node -ErrorAction:SilentlyContinue) -eq $null)
		{
			HighTitle 'nodejs'
			choco install -y nodejs --version 12.16.3
			# update session PATH so we can continue
			$npmpath = [Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';' | ? { $_ -match 'nodejs' }
			$env:PATH = (($env:PATH -split ';') -join ';') + ";$npmpath"
		}
		else
		{
			Write-Host 'Nodejs already installed' -ForegroundColor Green
		}
	}


	function InstallNotepadPP
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		if (UnChocolatized 'notepadplusplus')
		{
			Chocolatize 'notepadplusplus'
			Chocolatize 'npppluginmanager'

			$themes = "$env:ProgramFiles\notepad++\themes"
			New-Item $themes -ItemType Directory -Force
			Copy-Item "$home\Documents\WindowsPowerShell\Themes\Dark Selenitic npp.xml" "$themes\Dark Selenitic.xml"

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
			Write-Host 'Notepad++ already installed' -ForegroundColor Green
		}
	}


	function InstallS3Browser
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		if (UnChocolatized 's3browser')
		{
			Chocolatize 's3browser'
		}
		else
		{
			Write-Host 's3browser already installed' -ForegroundColor Green
		}
	}

	function InstallSourceTree
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		if (UnChocolatized 'sourcetree')
		{
			Chocolatize 'sourcetree'

			$reminder = 'SourceTree configuration', `
				' 0. Log into choose "BitBucket" option and logon Atlassian online', `
				' 1. Enabled Advanced/"Configure automatic line endings"', `
				' 2. Do not create an SSH key'

			$script:reminders += ,$reminder
			Highlight $reminder 'Cyan'
		}
		else
		{
			Write-Host 'SourceTree already installed' -ForegroundColor Green
		}
	}


	function InstallSysInternals
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		$target = "$tools\SysInternals"
		if (!(Test-Path $target))
		{
			HighTitle 'SysInternals'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null
			DownloadBootstrap 'SysInternals.zip' $target
		}
		else
		{
			Write-Host 'SysInternals already installed' -ForegroundColor Green
		}
	}


	function InstallTerminal
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		$parentId = (gwmi win32_process -Filter "processid='$pid'").parentprocessid
		if ((gwmi win32_process -Filter "processid='$parentId'").Name -eq 'WindowsTerminal.exe')
		{
			Write-Host 'Cannot install microsoft-windows-terminal from a Windows Terminal console' -ForegroundColor Red
			return
		}

		Chocolatize 'microsoft-windows-terminal'

		# customize settings... for Terminal v1.8.1444.0

		$0 = "$($env:LOCALAPPDATA)\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
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
		$settings.initialRows = 90

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


	function InstallThings
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		Chocolatize '7zip'
		Chocolatize 'adobereader'
		Chocolatize 'curl' # may be required for DownloadBootstrap
		Chocolatize 'git'
		Chocolatize 'googlechrome'
		Chocolatize 'greenshot'
		Chocolatize 'licecap' # live screen capture -> .gif utility
		Chocolatize 'linqpad' # free version; can add license (activation.txt)
		Chocolatize 'mRemoteNG'
		Chocolatize 'nuget.commandline'
		Chocolatize 'procexp'
		Chocolatize 'procmon'
		Chocolatize 'robo3t'
		Chocolatize 'sharpkeys'

		InstallBareTail
		InstallGreenfish
		InstallNotepadPP
	}


	function InstallVisualStudio
	{
		[CmdletBinding(HelpURI='manualcmd')] param()

		$0 = 'C:\Program Files (x86)\Microsoft Visual Studio\2019'
		$pro = Test-Path (Join-Path $0 'Professional\Common7\IDE\devenv.exe')
		$ent = Test-Path (Join-Path $0 'Enterprise\Common7\IDE\devenv.exe')
		if (!($pro -or $ent))
		{
			$sku = 'professional'
			if ($Enterprise) { $sku = 'enterprise' }

			HighTitle "Visual Studio 2019 ($sku)"
			Highlight '... This will take a few minutes'

			# download the installer
			$bits = "vs_$sku`_2019_16.10"
			DownloadBootstrap "$bits`.zip" $env:TEMP

			# run the installer
			& "$($env:TEMP)\$bits`.exe" --passive --config "$($env:TEMP)\vs_$sku`.vsconfig"

			$reminder = 'Visual Studio', `
				' .. When installation is complete, rerun this script using the InstallVSExtensions command'

			$script:reminders += ,$reminder
			Highlight $reminder 'Cyan'
		}
		else
		{
			Write-Host 'Visual Studio already installed' -ForegroundColor Green
		}
	}


	function InstallVSExtensions
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		HighTitle 'Visual Studio Extensions'
		$root = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
		$installer = "$root\Common7\IDE\vsixinstaller.exe"

		# TODO: update these versions very now and then...
		
		InstallVsix $installer 'EditorGuidelines' 'PaulHarrington/vsextensions/EditorGuidelines/2.2.5/vspackage'
		InstallVsix $installer 'InstallerProjects' 'VisualStudioClient/vsextensions/MicrosoftVisualStudio2017InstallerProjects/1.0.0/vspackage'
		InstallVsix $installer 'MarkdownEditor' 'MadsKristensen/vsextensions/MarkdownEditor/1.12.253/vspackage'
		InstallVsix $installer 'SonarLint' 'SonarSource/vsextensions/SonarLintforVisualStudio2019/4.29.0.25125/vspackage'
		InstallVsix $installer 'SpecFlow' 'TechTalkSpecFlowTeam/vsextensions/SpecFlowForVisualStudio/2019.0.71.42847/vspackage'
		InstallVsix $installer 'VSColorOutput' 'MikeWard-AnnArbor/vsextensions/VSColorOutput/2.73/vspackage'

		Write-Host
		Write-Host '... Wait a couple of minutes for the VSIXInstaller processes to complete before starting VS' -ForegroundColor Yellow
	}


	function InstallVsix
	{
		param($installer, $name, $uri)
		Write-Host "... installing $name extension in the background" -ForegroundColor Yellow

		$url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$uri"
		$vsix = "$($env:TEMP)\$name`.vsix"

		# download package directly from VS Marketplace and install
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
		$progressPreference = 'silentlyContinue'
		Invoke-WebRequest $url -OutFile $vsix
		$progressPreference = 'Continue'

		& $installer /quiet /norepair $vsix
	}


	function InstallVSCode
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		if (UnChocolatized 'vscode')
		{
			Chocolatize 'vscode'

			# path will be added to Machine space but it isn't there yet
			# so temporarily fix path so we can install add-ons
			$0 = 'C:\Program Files\Microsoft VS Code\bin'
			if (Test-Path $0)
			{
				$env:PATH = (($env:PATH -split ';') -join ';') + ";$0"

				Highlight 'Adding VSCode extensions...'
				code --install-extension alexkrechik.cucumberautocomplete
				code --install-extension anseki.vscode-color
				code --install-extension eg2.tslint
				code --install-extension ionutvmi.reg
				code --install-extension mikeburgh.xml-format
				code --install-extension ms-azuretools.vscode-docker
				code --install-extension ms-python.python
				code --install-extension ms-vscode-remote.remote-wsl
				code --install-extension ms-vscode.csharp
				code --install-extension ms-vscode.powershell
				code --install-extension msjsdiag.debugger-for-chrome
				code --install-extension sonarlint
				code --install-extension vscode-icons-team.vscode-icons
				# Vuln Cost - Security Scanner for VS Code
				code --install-extension snyk-security.vscode-vuln-cost	
				# swagger
				code --install-extension Arjun.swagger-viewer
				code --install-extension 42Crunch.vscode-openapi
				code --install-extension mermade.openapi-lint
			}
		}
		else
		{
			Write-Host 'VSCode already installed' -ForegroundColor Green
		}
	}


	# Extras  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	function InstallDateInTray
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

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
			Write-Host 'DateInTray already installed' -ForegroundColor Green
		}
	}


	function InstallWiLMa
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

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
			Write-Host 'WiLMa already installed' -ForegroundColor Green
		}
	}


	function InstallWmiExplorer
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		$target = "$tools\WmiExplorer"
		if (!(Test-Path $target))
		{
			HighTitle 'WmiExplorer'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null

			DownloadBootstrap 'wmiexplorer.zip' $target
		}
		else
		{
			Write-Host 'WmiExplorer already installed' -ForegroundColor Green
		}
	}
}
Process
{
	if ($ListCommands)
	{
		GetCommandList
		$ok = TestElevated
		return
	}
	elseif (!(TestElevated))
	{
		return
	}

	if ($AccessKey -and $SecretKey)
	{
		# harmless to do this even before AWS is installed
		ConfigureAws $AccessKey $SecretKey
	}
	<#
	elseif (!(TestAwsConfiguration))
	{
		return
	}
	#>

	# install chocolatey
	if ((Get-Command choco -ErrorAction:SilentlyContinue) -eq $null)
	{
		Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	}

	if ($command)
	{
		InvokeCommand $command
		return
	}

	if (Test-Path $stagefile)
	{
		$stage = (Get-Content $stagefile) -as [int]
		if ($stage -eq $null) { $stage = 0 }
	}

	if ($stage -eq 0)
	{
		InstallNetFx
		InstallHyperV
	}

	if (Get-ScheduledTask -TaskName $ContinuationName -ErrorAction:silentlycontinue)
	{
		Unregister-ScheduledTask -TaskName $ContinuationName -Confirm:$false
	}

	DisableCFG

	InstallThings
	InstallTerminal

	InstallMacrium

	# Development...

	InstallAWSCLI
	InstallNodeJs
	InstallAngular
	InstallVSCode
	InstallS3Browser
	#InstallSourceTree
	InstallSysInternals

	InstallDockerDesktop

	# Extras

	if ($Extras)
	{
		Chocolatize 'audacity' # audio editor
		Chocolatize 'dopamine' # music player
		Chocolatize 'paint.net'
		Chocolatize 'treesizefree'
		Chocolatize 'vlc'
		InstallDateInTray
		InstallWiLMa
		InstallWmiExplorer
	}

	# may reboot multiple times, so do it last
	InstallVisualStudio

	if (Test-Path $stagefile)
	{
		Remove-Item $stagefile -Force -Confirm:$false
	}

	$reminder = 'Consider these manually installed apps:', `
		' - AVG Antivirus', `
		' - BeyondCompare (there is a choco package but not for 4.0)', `
		' - ConEmu', `
		' - OneMore OneNote add-in (https://github.com/stevencohn/OneMore/releases)'

	$script:reminders += ,$reminder

	$line = New-Object String('*',80)
	Write-Host
	Write-Host $line -ForegroundColor Cyan
	Write-Host ' Reminders ...' -ForegroundColor Cyan
	Write-Host $line -ForegroundColor Cyan
	Write-Host

	$script:reminders | % { $_ | % { Write-Host $_ -ForegroundColor Cyan }; Write-Host }

	Write-Host '... Initialization compelete   ' -ForegroundColor Green
	Read-Host '... Press Enter to finish'
}
