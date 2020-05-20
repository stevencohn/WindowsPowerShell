<#
.SYNOPSIS
Automates the installation of applications, development tools, and other utilities.

.PARAMETER Command
Invoke a single command from this script; default is to run all.

.PARAMETER AccessKey
AWS access key used to download bits.

.PARAMETER Enterprise
Install Visual Studio Enterprise; default is to install Professional

.PARAMETER Extras
Installs more than most developers would need or want; this is my personalization.

.PARAMETER ListCommands
Show a list of all available commands.

.PARAMETER SecretKey
AWS secret key used to download bits.

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
	$bucket = 'cdsbits'
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
			Write-Verbose "$name already installed by chocolatey"
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
			Write-Verbose 'Hyper-V installed'
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
			Write-Verbose '.NET Framework 3.5 already installed'
		}

		if (((Get-Command dotnet -ErrorAction:SilentlyContinue) -eq $null) -or `
			((dotnet --list-sdks | ? { $_ -match '^2.2.' }).Count -eq 0))
		{
			# currently required for our apps, may change
			HighTitle '.NET Core 2.2'
			choco install -y dotnetcore-sdk --version=2.2.0
		}
		else
		{
			Write-Verbose '.NET Core 2.2 already installed'
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
			Write-Verbose 'Angular already installed'
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
			InstallAWSCLI

			HighTitle 'BareTail'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null

			aws s3 cp s3://$bucket/baretail.exe $target\
			aws s3 cp s3://$bucket/baretail-dark.udm $target\
			#Download 'https://baremetalsoft.com/baretail/download.php?p=m' $target\baretail.exe
		}
		else
		{
			Write-Verbose 'BareTail already installed'
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
			Write-Verbose 'Docker Desktop already installed'
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
			Write-Verbose 'Greenshot already installed'
		}
	}


	function InstallMacrium
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		if (!(Test-Path "$env:ProgramFiles\Macrium\Reflect"))
		{
			Chocolatize 'reflect-free'  # just the installer to C:\tools\

			$reminder = 'Macrium Reflect', `
				' 0. Double-click the Macrium Installer icon on the desktop after VS is installed', `
				' 1. Choose Free version, no registration is necessary'

			$script:reminders += ,$reminder
			Highlight $reminder 'Cyan'

			# This runs the downloader and leaves the dialog visible!
			#& $tools\ReflectDL.exe
		}
		else
		{
			Write-Verbose 'Macrium installer already installed'
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
			Write-Verbose 'Nodejs already installed'
		}
	}


	function InstallNotepadPP
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		if (UnChocolatized 'notepadplusplus')
		{
			Chocolatize 'notepadplusplus'
			Chocolatize 'npppluginmanager'

			# replace notepad.exe
			HighTitle 'Replacing notepad with notepad++'
			$0 = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe'
			$exe = (Get-Command 'notepad++').Source
			$cmd = """$exe"" -notepadStyleCmdline -z"
			if (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
			New-ItemProperty -Path $0 -Name 'Debugger' -Value $cmd -Force | Out-Null
		}
		else
		{
			Write-Verbose 'Notepad++ already installed'
		}
	}


	function InstallS3Browser
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		if (!(Test-Path 'C:\Program Files\S3 Browser'))
		{
			InstallAWSCLI

			HighTitle 'S3 Browser'
			aws s3 cp s3://$bucket/s3browser-8-5-9.exe $env:TEMP\s3browser.exe
			#Download 'https://netsdk.s3.amazonaws.com/s3browser/8.5.9/s3browser-8-5-9.exe' $env:TEMP\s3browser.exe
			& $env:TEMP\s3browser.exe /sp /supressmsgboxes /norestart /closeapplications /silent
		}
		else
		{
			Write-Verbose 'S3Browser already installed'
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
			Write-Verbose 'SourceTree already installed'
		}
	}


	function InstallThings
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		Chocolatize '7zip'
		Chocolatize 'git'
		Chocolatize 'googlechrome'
		Chocolatize 'greenshot'
		Chocolatize 'linqpad' # free version; can add license (activation.txt)
		Chocolatize 'mRemoteNG'
		Chocolatize 'nuget.commandline'
		Chocolatize 'procexp'
		Chocolatize 'procmon'
		Chocolatize 'robo3t'

		InstallBareTail
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
			InstallAWSCLI

			$sku = 'professional'
			if ($Enterprise) { $sku = 'enterprise' }

			HighTitle "Visual Studio 2019 ($sku)"
			Highlight '... This will take a few minutes'

			# download the installer
			$bits = "vs_$sku`_2019_16.4.exe"
			aws s3 cp s3://$bucket/$bits $env:TEMP\
			aws s3 cp s3://$bucket/vs_$sku.vsconfig $env:TEMP\.vsconfig

			# run the installer
			& $env:TEMP\$bits --passive --config $env:TEMP\.vsconfig

			$reminder = 'Visual Studio', `
				' 0. When installation is complete, rerun this script using the InstallVSExtensions command'

			$script:reminders += ,$reminder
			Highlight $reminder 'Cyan'
		}
		else
		{
			Write-Verbose 'Visual Studio already installed'
		}
	}


	function InstallVSExtensions
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		HighTitle 'Visual Studio Extensions'
		$root = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
		$installer = "$root\Common7\IDE\vsixinstaller.exe"

		InstallVsix $installer 'EditorGuidelines'
		InstallVsix $installer 'InstallerProjects'
		InstallVsix $installer 'Markdown_Editor_v1.12.236'
		InstallVsix $installer 'TechTalk.SpecFlow.VisualStudioIntegration'
		InstallVsix $installer 'VSColorOutput'

		Write-Host
		Write-Host '... Wait a couple of minutes for the VSIXInstaller processes to complete before starting VS' -ForegroundColor Yellow
	}


	function InstallVsix
	{
		param($installer, $name)
		Write-Host "... installing $name extension in the background" -ForegroundColor Yellow
		aws s3 cp s3://$bucket/$name.vsix $env:TEMP\
		& $installer /quiet /norepair $env:TEMP\$name.vsix
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
				code --install-extension vscode-icons-team.vscode-icons
				# swagger
				code --install-extension Arjun.swagger-viewer
				code --install-extension 42Crunch.vscode-openapi
			}
		}
		else
		{
			Write-Verbose 'VSCode already installed'
		}
	}


	# Extras  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	function InstallDateInTray
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		$target = "$tools\DateInTray"
		if (!(Test-Path $target))
		{
			InstallAWSCLI

			HighTitle 'DateInTray'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null

			# $0 = 'https://softpedia-secure-download.com/dl/ba833328e1e20d7848a5498418cb5796/5dfe1db7/100016805/software/os_enhance/DITSetup.exe'
			# $zip = "$target\DITSetup.zip"
			#Download $0 $zip
			aws s3 cp s3://$bucket/DITSetup.exe $target\

			# extract just the main program; must use 7z instead of Expand-Archive
			7z e $target\DITSetup.exe DateInTray.exe -o"$target" | Out-Null
			Remove-Item $target\DITSetup.exe -Force -Confirm:$false

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
			Write-Verbose 'DateInTray already installed'
		}
	}


	function InstallWiLMa
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		$target = "$tools\WiLMa"
		if (!(Test-Path $target))
		{
			InstallAWSCLI

			HighTitle 'WiLMa'
			New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null

			# $0 = 'http://www.stefandidak.com/wilma/winlayoutmanager.zip'
			$zip = "$target\winlayoutmanager.zip"
			#Download $0 $zip
			aws s3 cp s3://$bucket/winlayoutmanager.zip $target\
			Expand-Archive $zip -DestinationPath $target | Out-Null
			Remove-Item $zip -Force -Confirm:$false

			# Register WindowsLayoutManager sheduled task to run as admin
			$trigger = New-ScheduledTaskTrigger -AtLogOn
			$action = New-ScheduledTaskAction -Execute "$target\WinLayoutManager.exe"
			$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
			Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "WiLMa" -Principal $principal

			Start-Process $target\WinLayoutManager.exe -Verb runas
		}
		else
		{
			Write-Verbose 'WiLMa already installed'
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
	elseif (!(TestAwsConfiguration))
	{
		return
	}

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

	# run first so we have the aws CLI for downloads
	InstallAWSCLI

	InstallThings
	InstallMacrium

	# Development...

	InstallNodeJs
	InstallAngular
	InstallVSCode
	InstallS3Browser
	InstallSourceTree

	InstallDockerDesktop

	# Extras

	if ($Extras)
	{
		#Chocolatize 'dopamine' # music player
		Chocolatize 'paint.net'
		Chocolatize 'treesizefree'
		Chocolatize 'vlc'
		InstallDateInTray
		InstallWiLMa
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

	Write-Host '... Initialization compelte   ' -ForegroundColor Green
	Read-Host '... Press Enter to finish'
}
