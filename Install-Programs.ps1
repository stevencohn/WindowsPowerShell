<#
.SYNOPSIS
Installs extra programs and features.

.PARAMETER Command
Invoke a single command from this script; default is to run all

.PARAMETER Extras
Installs more than most developers would need or want; this is my personalization

.PARAMETER ListCommands
Show a list of all available commands

.DESCRIPTION
Install extra programs and features. Should be run after Initialize-Machine.ps1
and all updates are installed.

Tested on Windows 10 update 1909
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[parameter(Position = 0)] $command,
	[switch] $Extras,
	[switch] $ListCommands
)

Begin
{
	$stage = 0
	$stagefile = (Join-Path $env:LOCALAPPDATA 'install-programs.stage')
	$ContinuationName = 'Install-Programs-Continuation'
	$tools = 'C:\tools'


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
	}


	function Download
	{
		param($uri, $target)
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12';
		Invoke-WebRequest -Uri $uri -OutFile $target
	}


	function Highlight
	{
		param($text = '')
		$text | Write-Host -ForegroundColor Black -BackgroundColor Yellow
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

		$exarg = ''
		if ($Extras) { $exarg = '-Extras' }
		$cmd = $MyInvocation.MyCommand.Path
		$cmd = "$cmd $exarg"
		Write-Host "Command=[$cmd]"
		read-host 'stop'

		# ensure Hyper-V
		if (!(HyperVInstalled))
		{
			HighTitle 'Hyper-V'
			Highlight '', '... Reboot will be required after installing Hyper-V', `
				'... This script will continue automagically after the reboot'

			Read-Host '... Press Enter to continue or Ctrl-C to abort'

			Set-Content $stagefile '1' -Force
			$script:stage = 1

			# prep a logon continuation task
			$exarg = ''
			if ($Extras) { $exarg = '-Extras' }
			$trigger = New-ScheduledTaskTrigger -AtLogOn;
			$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-command '$PSCommandPath $exarg'"
			$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest;
			Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $ContinuationName -Principal $principal | Out-Null

			# this will force a reboot
			Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
		}
		else
		{
			$script:stage = 1
		}
	}

	function HyperVInstalled
	{
		((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -eq 'Enabled')
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

		# disable Code Flow Guard (CFG) for vmcompute service
		Set-ProcessMitigation -Name 'C:\WINDOWS\System32\vmcompute.exe' -Disable CFG
		Set-ProcessMitigation -Name 'C:\WINDOWS\System32\vmcompute.exe' -Disable StrictCFG
		# restart service
		net stop vmcompute
		net start vmcompute
	}


	function InstallBareTail
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		if (!(Test-Path "$tools\BareTail"))
		{
			HighTitle 'BareTail'
			$target = "$tools\BareTail"
			if (!(Test-Path $target))
			{
				New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null
			}

			Download 'https://baremetalsoft.com/baretail/download.php?p=m' $target\baretail.exe
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

		Chocolatize 'docker-desktop'

		Highlight '', 'Docker Desktop installed', `
			'- restart console window to get updated PATH', `
			'- unsecure repos must be added manually'
	}


	function InstallMacrium
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		Chocolatize 'reflect-free' # just the installer to C:\tools\
		Highlight '... Macrium installer started but it must be completed manually (wait for this script to finish)', `
			'... Choose Home version, no registration is necessary', `
			''

		# This runs the downloader and leaves the dialog visible!
		& $tools\ReflectDL.exe
	}


	function InstallNodeJs
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		HighTitle 'nodejs'
		choco install -y nodejs --version 10.15.3
		# update session PATH so we can continue
		$npmpath = [Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';' | ? { $_ -match 'nodejs' }
		$env:PATH = (($env:PATH -split ';') -join ';') + ";$npmpath"
	}

	function InstallAngular
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		HighTitle 'angular'
		npm install -g @angular/cli@7.3.8
		npm install -g npm-check-updates
		npm install -g local-web-server
	}


	function InstallThings
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		Chocolatize '7zip'
		Chocolatize 'awscli'
		Chocolatize 'git'
		Chocolatize 'googlechrome'
		Chocolatize 'greenshot'
		Chocolatize 'linqpad'  # free version; can add license (activation.txt)
		Chocolatize 'mRemoteNG'
		Chocolatize 'notepadplusplus'
		Chocolatize 'npppluginmanager'
		Chocolatize 'nuget.commandline'
		Chocolatize 'robo3t'

		InstallBareTail
	}


	function InstallS3Browser
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		if (!(Test-Path 'C:\Program Files\S3 Browser'))
		{
			HighTitle 'S3 Browser'
			Download 'https://netsdk.s3.amazonaws.com/s3browser/8.5.9/s3browser-8-5-9.exe' $env:TEMP\s3browser.exe
			& $env:TEMP\s3browser.exe /sp /supressmsgboxes /norestart /closeapplications /silent
		}
	}

	function InstallSourceTree
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()
		Chocolatize 'sourcetree'

		Highlight 'SourceTree: first time run...', `
			'- Log into choose "BitBucket" option and logon Atlassian online', `
			'- Enabled Advanced/"Configure automatic line endings"', `
			'- Do not create an SSH key'
	}


	function InstallVisualStudio
	{
		[CmdletBinding(HelpURI='manualcmd')] param()
		# get the installer
		# $ProgressPreference = 'SilentlyContinue';
		# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12';
		# Invoke-WebRequest -Uri https://<someurl>/vs_Enterprise.exe -OutFile $home\Downloads\vs2019.exe;
		# Invoke-WebRequest -Uri https://<someurl>/.vsconfig -OutFile C:\.vsconfig;
		# # run the installer
		# & C:\vs2019.exe --config c:\.vsconfig;
		# # delete the installer
		# Remove-Item C:\vs2019.exe -Force -Confirm:$false

		Highlight '... Remember to update nuget package sources', '', `
			'... Add these extensions manually:', `
			'... Markdown Editor', `
			'... Microsoft Visual Studio Installer Projects', `
			'... VSColorOutput', `
			'... SpecFlow for Visual Studio 2019', `
			'... Editor Guidelines'
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
			}
		}
	}


	# Extras  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	function InstallDateInTray
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		if (!(Test-Path $tools\DateInTray))
		{
			HighTitle 'DateInTray'
			$target = "$tools\DateInTray"

			if (!(Test-Path $target))
			{
				New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null
			}

			$0 = 'https://softpedia-secure-download.com/dl/ba833328e1e20d7848a5498418cb5796/5dfe1db7/100016805/software/os_enhance/DITSetup.exe'
			$zip = "$target\DateInTray.zip"
			Download $0 $zip

			# extract just the main program; must use 7z instead of Expand-Archive
			7z e $zip DateInTray.exe
			Remove-Item $zip -Force -Confirm:$false
		}
	}


	function InstallWiLMa
	{
		[CmdletBinding(HelpURI = 'manualcmd')] param()

		if (!(Test-Path "$tools\WiLMa"))
		{
			HighTitle 'WiLMa'
			$target = "$tools\WiLMa"

			if (!(Test-Path $target))
			{
				New-Item $target -ItemType Directory -Force -Confirm:$false | Out-Null
			}

			$0 = 'http://www.stefandidak.com/wilma/winlayoutmanager.zip'
			$zip = "$target\winlayoutmanager.zip"
			Download $0 $zip
			Expand-Archive $zip -DestinationPath $target
			Remove-Item $zip -Force -Confirm:$false

			# Register WindowsLayoutManager sheduled task to run as admin
			$trigger = New-ScheduledTaskTrigger -AtLogOn;
			$action = New-ScheduledTaskAction -Execute "$target\WindowsLayoutManager.exe";
			$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest;
			Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "WiLMa" -Principal $principal;
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
		InstallHyperV
	}

	if (get-scheduledtask -taskname $ContinuationName -ErrorAction:silentlycontinue)
	{
		Unregister-ScheduledTask -TaskName $ContinuationName -Confirm:$false
	}

	DisableCFG

	InstallThings
	InstallMacrium

	# Development...

	InstallNodeJs
	InstallAngular
	InstallVSCode
	#InstallVisualStudio
	InstallSourceTree

	InstallDockerDesktop

	# Extras

	if ($Extras)
	{
		Chocolatize 'musicbee'
		Chocolatize 'paint.net'
		Chocolatize 'treesizefree'
		Chocolatize 'vlc'
		InstallDateInTray
		InstallWiLMa
	}

	Highlight '', `
		'Other recommendation that must be installed manually:', `
		'- BeyondCompare (there is a choco package but not for 4.0)', `
		'- ConEmu', `
		'- DateInTray', `
		'- OneMore OneNote add-in (https://github.com/stevencohn/OneMore/releases)', `
		'', `
		'Initialization compelte'

	if (Test-Path $stagefile)
	{
		Remove-Item $stagefile -Force -Confirm:$false
	}
}
