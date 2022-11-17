<#
.SYNOPSIS
Sets up a new machine with a custom configuration and PowerShell profile.

.PARAMETER Command
Invoke a single command from this script; default is to run all

.PARAMETER ListCommands
Show a list of all available commands
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[parameter(Position=0)] $command,
	[switch] $ListCommands
)

Begin
{
	. $PSScriptRoot\common.ps1


	function CreateHeadlessPowerPlan()
	{
		[System.ComponentModel.Description(
			'Create a power plan suitable for long-running backup or watching movies over HDMI')]
		[CmdletBinding(HelpURI='cmd')] param()

		# create a power plan, duplicate of Balanced, that adjusts the screen
		# brightness to zero; used during backups and watching movies over HDMI :)

		# unique ID generated just for our custom power plan
		$headlessGuid = '1015f01d-73d6-47dd-906b-dc8af8cd7711'

		if (powercfg /list | ? { $_.Contains($headlessGuid) })
		{
			Write-Verbose 'Headless power scheme already exists'
			return
		}

		# these are well-known hard-coded values in Windows 10 21H1
		# I do not know the first version in which they appeared
		$balancedGuid = '381b4222-f694-41f0-9685-ff5bb260df2e'
		$displayGuid = '7516b95f-f776-4464-8c53-06167f40cc99'
		$brightnessGuid = 'aded5e82-b909-4619-9949-f5d71dac0bcb'

		powercfg /duplicatescheme $balancedGuid $headlessGuid | Out-Null
		powercfg /changename $headlessGuid 'Headless' 'Run backups or watch movies'
		powercfg /setacvalueindex $headlessGuid $displayGuid $brightnessGuid 0
		powercfg /setdcvalueindex $headlessGuid $displayGuid $brightnessGuid 0
	}


	function DisableHomeGroups
	{
		[System.ComponentModel.Description('Disable the useless Home Groups feature')]
		[CmdletBinding(HelpURI='cmd')] param()

		# DisableHomeGroups
		Write-Verbose 'stopping and disabling Home Groups services'
		if (Get-Service HomeGroupListener -ErrorAction:SilentlyContinue)
		{
			Stop-Service 'HomeGroupListener' -WarningAction SilentlyContinue
			Set-Service 'HomeGroupListener' -StartupType Disabled
			Stop-Service 'HomeGroupProvider' -WarningAction SilentlyContinue
			Set-Service 'HomeGroupProvider' -StartupType Disabled
		}
	}


	function DisableOneDrive
	{
		[System.ComponentModel.Description('Disable OneDrive, useful for test machines and VMs')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'disabling OneDrive...'
		$0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'
		If (!(Test-Path $0)) { New-Item -Path $0 | Out-Null }
		Set-ItemProperty $0 -Name 'DisableFileSyncNGSC' -Type DWord -Value 1

		if ($PSVersionTable.PSEdition -ne 'Desktop') {
			return
		}

		Write-Verbose 'attempting to uninstall OneDrive'

		Write-Output "Uninstalling OneDrive..."
		Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
		Start-Sleep -s 2
		$onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
		if (!(Test-Path $onedrive)) {
			$onedrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
		}

		if (Test-Path $onedrive)
		{
			try
			{
				Start-Process $onedrive "/uninstall" -NoNewWindow -Wait -ErrorAction Stop
				Start-Sleep -s 2
				Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
				Start-Sleep -s 2
				Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
				Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
				Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
				Remove-Item -Path "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue

				EnsureHKCRDrive
				Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
				Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
			}
			catch
			{
				$log = "${env:PROGRAMDATA}\Initialize-Machine-Exception.log"
				ConvertTo-Json $_.Exception | Out-File $log
				Write-Verbose "EXCEPTION written to $log"
			}
		}
	}


	function DisableZipFolders
	{
		[System.ComponentModel.Description(
			'Disable default Zip folder integration in Windows Explorer, increasing performance')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'disabling default Windows Zip folder Explorer integration'

		# take ownership of all Compressed Folders keys (e.g. replacing with 7-Zip)
		Set-RegistryOwner 'HKCR' 'CLSID\{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31}';
		Set-RegistryOwner 'HKCR' 'CLSID\{0CD7A5C0-9F37-11CE-AE65-08002B2E1262}';
		Set-RegistryOwner 'HKLM' 'SOFTWARE\WOW6432Node\Classes\CLSID\{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31}';
		Set-RegistryOwner 'HKLM' 'SOFTWARE\WOW6432Node\Classes\CLSID\{0CD7A5C0-9F37-11CE-AE65-08002B2E1262}';

		# remove all Compressed Folders keys; back-ticks required to escape curly braces
		Remove-Item -Path Registry::HKEY_CLASSES_ROOT\CLSID\`{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31`} -Force -Recurse -ErrorAction SilentlyContinue;
		Remove-Item -Path Registry::HKEY_CLASSES_ROOT\CLSID\`{0CD7A5C0-9F37-11CE-AE65-08002B2E1262`} -Force -Recurse -ErrorAction SilentlyContinue;
		Remove-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\CLSID\`{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31`} -Force -Recurse -ErrorAction SilentlyContinue;
		Remove-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\CLSID\`{0CD7A5C0-9F37-11CE-AE65-08002B2E1262`} -Force -Recurse -ErrorAction SilentlyContinue;
	}


	function EnableHyperVEnhancedMode
	{
		[System.ComponentModel.Description(
			'Disable Windows Hello to allow Enhanced mode sessions for Hyper-V VMs')]
		[CmdletBinding(HelpURI='cmd')] param()

		# fixes the problem where you can't log on when connecting to a VM in enhanced mode due
		# to a conflict in how Windows Hello works, so must disable it to allow enhanced mode

		# are we running in a Hyper-V VM?
		if ((gwmi Win32_BaseBoard).Manufacturer -eq 'Microsoft Corporation')
		{
			Write-Verbose 'disabling Windows Hello for this VM'
			# 0=disabled, 2=enabled
			$0 = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
			Set-ItemProperty $0 -Name 'DevicePasswordLessBuildVersion' -Type DWord -Value 0	
		}
	}


	function EnablePhotoViewer
	{
		[System.ComponentModel.Description(
			'Restore traditional Windows Photo Viewer and set as default viewer')]
		[CmdletBinding(HelpURI='cmd/extra')] param()

		Write-Verbose 'associating the good old Photo Viewer'

		# global preferences for all users
		$pvcmd = '%SystemRoot%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1'

		EnsureHKCRDrive
		@('Paint.Picture', 'giffile', 'jpegfile', 'icofile', 'pngfile') | % `
		{
			$0 = "HKCR:\$_\shell\open"
			New-Item -Path $0 -Force | Out-Null
			New-Item -Path "$0\command" | Out-Null
			Set-ItemProperty $0 -Name 'MuiVerb' -Type ExpandString -Value '@%ProgramFiles%\Windows Photo Viewer\photoviewer.dll,-3043'
			Set-ItemProperty "$0\command" -Name '(Default)' -Type ExpandString -Value $pvcmd
		}

		Write-Verbose 'adding Photo Viewer to "Open with..."'
		$0 = 'HKCR:\Applications\photoviewer.dll\shell\open'
		New-Item -Path "$0\command" -Force | Out-Null
		New-Item -Path "$0\DropTarget" -Force | Out-Null
		Set-ItemProperty $0 -Name 'MuiVerb' -Type String -Value '@photoviewer.dll,-3043'
		Set-ItemProperty "$0\command" -Name '(Default)' -Type ExpandString -Value $pvcmd
		Set-ItemProperty "$0\DropTarget" -Name 'Clsid' -Type String -Value '{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}'

		# current user preferences
		$0 = 'HKCU:\Software\Classes'
		@('jpg', 'jpeg', 'gif', 'png', 'bmp', 'tiff', 'ico') | % `
		{
			Set-ItemProperty "$0\.$_" -Name '(Default)' -Type String -Value 'PhotoViewer.FileAssoc.Tiff'
		}
	}

	function EnableRemoteDesktop
	{
		[System.ComponentModel.Description(
			'Enable Remote Desktop hosting, for Windows Pro editions only')]
		[CmdletBinding(HelpURI='cmd')] param()

		if (IsWindowsHomeEdition) {
			WriteWarn 'Remote Desktop cannot be enabled on Windows Home edition'
			return
		}

		Write-Verbose 'enabling Remote Desktop w/o Network Level Authentication...'
		$0 = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
		Set-ItemProperty $0 -Name 'fDenyTSConnections' -Type DWord -Value 0
		Set-ItemProperty "$0\WinStations\RDP-Tcp" -Name 'UserAuthentication' -Type DWord -Value 0
		Enable-NetFirewallRule -Name 'RemoteDesktop*'
	}


	function FixAirpodConnectivity
	{
		[System.ComponentModel.Description('Fixes airpod connectivity and pairing issues')]
		[CmdletBinding(HelpURI='cmd')] param()

		# If airpods will pair but then continually lose connection after manually connecting...
		# this disables power management on the Intel(R) Wireless Bluetooth(R) device
		$0 = 'HKLM:\SYSTEM\ControlSet001\Control\Class\{e0cbf06c-cd8b-4647-bb8a-263b43f0f974}\0000'
		if (Test-Path $0)
		{
			Set-ItemProperty $0 -Name 'PnPCapabilities' -Type String -Value '24'
		}

		# enabled Device Manager >> HID >> Power Management tab 
		# used to disable power management of Bluetooth Low Energy devices, like Airpods
		$0 = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'
		Set-ItemProperty $0 -Name 'CsEnabled' -Type DWord -Value 0
	}


	function GetPowerShellProfile
	{
		[System.ComponentModel.Description('Install the WindowsPowerShell profile')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'fetching WindowsPowerShell environment'

		Push-Location ([Environment]::GetFolderPath('MyDocuments'))
		git clone https://github.com/stevencohn/WindowsPowerShell.git
		Pop-Location
	}


	function GetYellowCursors
	{
		[System.ComponentModel.Description(
			'Install yellow mouse cursors making it easier to find the cursor on the screen')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'enabling yellow mouse cursors'

		Push-Location ([Environment]::GetFolderPath('MyDocuments'))
		git clone https://github.com/stevencohn/YellowCursors.git
		Push-Location YellowCursors
		.\Install.ps1
		Pop-Location
		Remove-Item YellowCursors -Recurse -Force
		Pop-Location
	}


	function InstallTools
	{
		[System.ComponentModel.Description('Install chocolatey, Git, and 7Zip')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'installing helper tools'

		InstallChocolatey
		InstallGit

		# install 7-Zip
		if ((Get-Command 7z -ErrorAction:SilentlyContinue) -eq $null)
		{
			choco install -y 7zip
		}
	}


	function RemoveCrapware
	{
		[System.ComponentModel.Description('The name says it all')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'removing crapware (some exceptions may appear)'
		$global:ProgressPreference = 'SilentlyContinue'

		# Microsoft crapware
		Get-AppxPackage *contactsupport* | Remove-AppxPackage

		@('3DBuilder', 'BingFinance', 'BingNews', 'BingSports', 'BingTranslator', 'BingWeather',
		'CommsPhone', 'Messaging', 'Microsoft3DViewer', 'MicrosoftOfficeHub', 'MicrosoftPowerBIForWindows',
		'MicrosoftSolitaireCollection', 'MicrosoftStickyNotes', 'MinecraftUWP', 'NetworkSpeedTest',
		'Office.OneNote', 'Office.Sway', 'OneConnect', 'People', 'Print3D', 'Microsoft.ScreenSketch',
		'SkypeApp', 'Wallet', 'WindowsAlarms', 'WindowsCamera', 'WindowsCommunicationsapps',
		'WindowsFeedbackHub', 'WindowsMaps', 'WindowsPhone', 'Windows.Photos', 'WindowsSoundRecorder',
		'YourPhone', 'ZuneMusic', 'ZuneVideo') | % `
		{
			Get-AppxPackage "Microsoft.$_" | Remove-AppxPackage
		}

		# Paint 3D
		Get-AppxPackage Microsoft.MSPaint | Remove-AppxPackage
		$0 = 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations'
		@('3mf', 'bmp', 'fbx', 'gif', 'jfif', 'jpe', 'jpeg', 'jpg', 'png', 'tif', 'tiff') | % `
		{
			$keypath = "$0\.$_\Shell\3D Edit"
			if (Test-Path $keypath)
			{
				Remove-Item $keypath -Force -Recurse -Confirm:$false
			}
		}

		# third party crap
		@('2414FC7A.Viber', '41038Axilesoft.ACGMediaPlayer', '46928bounde.EclipseManager', '4DF9E0F8.Netflix',
		'64885BlueEdge.OneCalendar', '7EE7776C.LinkedInforWindows', '828B5831.HiddenCityMysteryofShadows',
		'89006A2E.AutodeskSketchBook', '828B5831.HiddenCityMysteryofShadows', '9E2F88E3.Twitter', 'A278AB0D.DisneyMagicKingdoms',
		'A278AB0D.DragonManiaLegends', 'A278AB0D.MarchofEmpires', 'ActiproSoftwareLLC.562882FEEB491',
		'AdobeSystemsIncorporated.AdobePhotoshopExpress', 'CAF9E577.Plex', 'D52A8D61.FarmVille2CountryEscape',
		'D5EA27B7.Duolingo-LearnLanguagesforFree', 'DB6EA5DB.CyberLinkMediaSuiteEssentials',
		'DolbyLaboratories.DolbyAccess', 'Drawboard.DrawboardPDF', 'E046963F.LenovoCompanion', 'Facebook.Facebook',
		'flaregamesGmbH.RoyalRevolt2', 'GAMELOFTSA.Asphalt8Airborne', 'KeeperSecurityInc.Keeper', 'king.com.BubbleWitch3Saga',
		'king.com.CandyCrushSaga', 'king.com.CandyCrushSodaSaga', 'LenovoCorporation.LenovoID', 'LenovoCorporation.LenovoSettings',
		'Nordcurrent.CookingFever', 'PandoraMediaInc.29680B314EFC2', 'SpotifyAB.SpotifyMusic', 'WinZipComputing.WinZipUniversal',
		'XINGAG.XING') | % `
		{
			Get-AppxPackage $_ | Remove-AppxPackage
		}

		# Xbox
		@('XboxApp', 'XboxIdentityProvider', 'XboxSpeechToTextOverlay', 'XboxGamingOverlay', 'Xbox.TCUI') | % `
		{
			Get-AppxPackage "Microsoft.$_" | Remove-AppxPackage
		}
		Set-ItemProperty 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Value 0
		$0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
		if (!(Test-Path $0)) { New-Item -Path $0 | Out-Null }
		Set-ItemProperty $0 -Name 'AllowGameDVR' -Type DWord -Value 0

		$global:ProgressPreference = 'Continue'

		# unpin Microsoft Store game links
		<#
		# Unfortunately, new accounts come with Start Menu tiles that are links to Store games
		# and those aren't included in the list of items below, so the investigation continues...
		#
		https://drive.google.com/file/d/0B9oZLqAezog6TFRPRmlkSjhLMUk/view?usp=sharing
		$items = (New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items()
		$items | % { $x=$_; $_.Verbs() } | ? { $_.Name -match 'Un.*pin from Start' } | % { $x.Name  }
		#>
	}


	function ScheduleTempCleanup
	{
		[System.ComponentModel.Description(
			'Create a scheduled task to clean TEMP folders nightly')]
		[CmdletBinding(HelpURI='cmd')] param()

		# purge the current user's TEMP folder every morning at 5am
		$trigger = New-ScheduledTaskTrigger -Daily -At 5am;
		$action = New-ScheduledTaskAction -Execute "powershell.exe" `
			-Argument '-Command "Start-Transcript %USERPROFILE%\purge.log; Clear-Temp"'

		$task = Get-ScheduledTask -TaskName 'Purge TEMP' -ErrorAction:SilentlyContinue
		if ($task -eq $null)
		{
			Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Purge TEMP" -RunLevel Highest
		}
	}


	function SetConsoleProperties
	{
		[System.ComponentModel.Description(
			'Set Windows Console properties, colors, font, and buffer size')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'setting console properties'

		Set-Colors -Theme ubuntu

		# font
		Set-ItemProperty HKCU:\Console -Name 'FaceName' -Value 'Lucida Console' -Force
		Set-ItemProperty HKCU:\Console -Name 'FontSize' -Value 0x000c0000 -Force

		# history=100, rows=9999
		Set-ItemProperty HKCU:\Console -Name 'HistoryBufferSize' -Value 0x64 -Force
		Set-ItemProperty HKCU:\Console -Name 'ScreenBufferSize' -Value 0x2329008c -Force
	}


	function SetExplorerProperties
	{
		[System.ComponentModel.Description(
			'Customize Explorer visualizations and behaviors')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'setting explorer properties'

		# desktop view small icons (is this section needed or just TaskbarSmallIcons below?)
		$0 = 'HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop'
		Set-ItemProperty $0 -Name 'IconSize' -Value 32 -Type DWord
		Set-ItemProperty $0 -Name 'Mode' -Value 1 -Type DWord
		Set-ItemProperty $0 -Name 'LogicalViewMode' -Value 3 -Type DWord

		# hide taskbar search box
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
		Set-ItemProperty $0 -Name 'SearchboxTaskbarMode' -Type DWord -Value 0

		# hide People icon
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
		if (!(Test-Path $0)) { New-Item -Path $0 | Out-Null }
		Set-ItemProperty $0 -Name 'PeopleBand' -Type DWord -Value 0

		$0 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

		if (!(IsWindows11))
		{
			# taskbar small buttons
			Set-ItemProperty $0 -Name 'TaskbarSmallIcons' -Value 1 -Type DWord
			# hide widgets panel
			Set-ItemProperty $0 -Name 'TaskbarDa' -Value 0 -Type DWord
			# hide chat icon
			Set-ItemProperty $0 -Name 'TaskbarMn' -Value 0 -Type DWord
		}

		# disable item checkboxes
		Set-ItemProperty $0 -Name 'AutoCheckSelect' -Value 0 -Type DWord
		# replace cmd prompt with PowerShell
		Set-ItemProperty $0 -Name 'DontUsePowerShellOnWinX' -Value 0 -Type DWord
		# show known file extensions - must restart Explorer.exe
		Set-ItemProperty $0 -Name 'HideFileExt' -Type DWord -Value 0
		# show hidden files
		Set-ItemProperty $0 -Name 'Hidden' -Type DWord -Value 1
		# change default Explorer view to This PC
		Set-ItemProperty $0 -Name 'LaunchTo' -Type DWord -Value 1
		# expand to current folder
		Set-ItemProperty $0 -Name 'NavPaneExpandToCurrentFolder' -Type DWord -Value 1
		# show all folders
		Set-ItemProperty $0 -Name 'NavPaneShowAllFolders' -Type DWord -Value 1

		# expand the ribbon bar
		$0 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Ribbon'
		if (!(Test-Path $0)) { New-Item -Path $0 | Out-Null }
		Set-ItemProperty $0 -Name 'MinimizedStateTabletModeOff' -Type DWord -Value 0

		# move Libraries folder above This PC (0x42 above, 0x54 below)
		EnsureHKCRDrive
		$0 = 'HKCR:\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}'
		Set-RegistryOwner 'HKCR' 'CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}'
		Set-ItemProperty $0 -Name 'SortOrderIndex' -Type DWord -Value 0x42

		# hide recent shortcuts
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
		Set-ItemProperty $0 -Name 'ShowRecent' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'ShowFrequent' -Type DWord -Value 0
		# disable "-shortcut" suffix to newly created shortcuts, first byte must be 0
		Set-ItemProperty $0 -Name 'link' -Type Binary -Value ([byte[]](0,0,0,0))

		# unpin all items from Quick access
		$shapp = New-Object -ComObject shell.application
		$shapp.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | % { $_.InvokeVerb("unpinfromhome") }
		# hide Quick access (delete HubMode value to reenable)
		$0 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
		Set-ItemProperty $0 -Name 'HubMode' -Type DWord -Value 1 -Force | Out-Null

		# hide 3D Objects folder
		$k = '{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'
		$0 = 'Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace'
		if (Test-Path "HKLM:\SOFTWARE\$0\$k")
		{
			Rename-Item "HKLM:\SOFTWARE\$0\$k" -NewName ":$k"
			Rename-Item "HKLM:\SOFTWARE\WOW6432Node\$0\$k" -NewName ":$k"
		}

		# restore traditional Win10 context menu (delete GUID key to revert to new style)
		#reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

		# set Dark mode
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
		New-ItemProperty $0 -Name 'AppsUseLightTheme' -Value 0 -Type dword -Force | Out-Null
		New-ItemProperty $0 -Name 'SystemUsesLightTheme' -Value 0 -Type dword -Force | Out-Null

		# set accent color
		$0 = 'HKCU:\Software\Microsoft\Windows\DWM'
		New-ItemProperty $0 -Name 'ColorizationColor' -Value 0xc4767676 -Type dword -Force | Out-Null
		New-ItemProperty $0 -Name 'ColorizationAfterglow' -Value 0xc4767676 -Type dword -Force | Out-Null
		New-ItemProperty $0 -Name 'AccentColor' -Value 0xff767676 -Type dword -Force | Out-Null

		# disable Autoplay
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers'
		Set-ItemProperty $0 -Name 'DisableAutoplay' -Type DWord -Value 1

		# disable Autorun for all drives - ALL USERS
		$0 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
		if (!(Test-Path $0)) { New-Item -Path $0 | Out-Null }
		Set-ItemProperty $0 -Name 'NoDriveTypeAutoRun' -Type DWord -Value 255

		$0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
		if (!(Test-Path $0)) { New-Item -Path $0 | Out-Null }
		# unlock start menu customization. Some companies set this to prevent stupid users
		# from rearranging the start menu icons.
		Set-ItemProperty $0 -Name 'LockedStartLayout' -Type DWord -Value 0
		# hide Recently Added apps sections from Start menu
		Set-ItemProperty $0 -Name 'HideRecentlyAddedApps' -Type DWord -Value 1

		if (!(IsWindows11))
		{
			# set Details tab as default in Task Manager, Windows 10 only :-(
			# 0=Processes 1=Performance 2=AppHistory 3=Startup 4=Users 5=Details 6=Services
			$0 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager' 
			Set-ItemProperty $0 -Name 'StartUpTab' -Type DWord -Value 5
		}

		# restart explorer.exe
		Stop-Process -Name explorer
	}


	function SetExtras
	{
		[System.ComponentModel.Description(
			'Configure Windows, disabling all tracking and useless performance sinks')]
		[CmdletBinding(HelpURI='cmd')] param()

		# DisableAppSuggestions
		Write-Verbose 'disabling application suggestions'
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
		Set-ItemProperty $0 -Name 'ContentDeliveryAllowed' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'OemPreInstalledAppsEnabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'PreInstalledAppsEnabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'PreInstalledAppsEverEnabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'SilentInstalledAppsEnabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'SubscribedContent-338387Enabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'SubscribedContent-338388Enabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'SubscribedContent-338389Enabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'SubscribedContent-338393Enabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'SubscribedContent-353698Enabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'SystemPaneSuggestionsEnabled' -Type DWord -Value 0
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
		Set-ItemProperty $0 -Name 'Start_TrackProgs' -Type DWord -Value 0
		$0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
		if (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'DisableWindowsConsumerFeatures' -Type DWord -Value 1

		# DisableActivityHistory
		Write-Verbose 'disabling activity history'
		$0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
		Set-ItemProperty $0 -Name "EnableActivityFeed" -Type DWord -Value 0
		Set-ItemProperty $0 -Name "PublishUserActivities" -Type DWord -Value 0
		Set-ItemProperty $0 -Name "UploadUserActivities" -Type DWord -Value 0

		# DisableLocationTracking
		Write-Verbose 'disabling location tracking'
		$0 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
		If (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'Value' -Type String -Value 'Deny'
		Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}' -Name 'SensorPermissionState' -Type DWord -Value 0
		Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration' -Name 'Status' -Type DWord -Value 0

		# DisableFeedback and ComptTelRunner.exe
		Write-Verbose 'disabling feedback'
		$0 = 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules';
		If (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null };
		Set-ItemProperty $0 -Name 'NumberOfSIUFInPeriod' -Type DWord -Value 0;
		Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'DoNotShowFeedbackNotifications' -Type DWord -Value 1;
		Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'Allow Telemetry' -Type DWord -Value 0;
		Disable-ScheduledTask -TaskName 'Microsoft\Windows\Feedback\Siuf\DmClient' -ErrorAction SilentlyContinue | Out-Null;
		Disable-ScheduledTask -TaskName 'Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload' -ErrorAction SilentlyContinue | Out-Null;
		Disable-ScheduledTask -TaskName 'Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser' -ErrorAction SilentlyContinue | Out-Null;

		# DisableTailoredExperiences
		Write-Verbose 'disabling tailored experiences'
		$0 = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
		If (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'DisableTailoredExperiencesWithDiagnosticData' -Type DWord -Value 1

		# DisableAdvertisingID
		Write-Verbose 'disabling advertising ID'
		$0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
		If (!(Test-Path $0)) { New-Item -Path $0 | Out-Null }
		Set-ItemProperty $0 -Name 'DisabledByGroupPolicy' -Type DWord -Value 1

		# DisableWebSearch
		Write-Verbose 'disabling Bing Search in Start menu'
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
		Set-ItemProperty $0 -Name 'BingSearchEnabled' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'CortanaConsent' -Type DWord -Value 0

		# DisableWidgets
		if (IsWindows11)
		{
			$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
			if (Test-Path $0) { Set-ItemProperty $0 -Name 'TaskbarDa' -Type DWord -Value 0 }
		}

		# Limit Cortana
		Write-Verbose "Limiting Cortana..."
		$0 = 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings'
		If (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'AcceptedPrivacyPolicy' -Type DWord -Value 0
		$0 = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization'
		if (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'RestrictImplicitTextCollection' -Type DWord -Value 1
		Set-ItemProperty $0 -Name 'RestrictImplicitInkCollection' -Type DWord -Value 1
		$0 = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore'
		if (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'HarvestContacts' -Type DWord -Value 0

		# enable Hibernate option
		Write-Verbose 'enabling hibernate option'
		powercfg /h on
	}


	function DisableCortana
	{
		[System.ComponentModel.Description('Disable Cortana search preserving excessive CPU')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose "Disabling Cortana..."
		$0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
		if (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'AllowCortana' -Type DWord -Value 0

		# Block Cortana SearchUI (uses excessive CPU)
		$0 = 'C:\Windows\SystemApps\Microsoft.Windows.Cortana_cw5n1h2txyewy'
		if (Test-Path "$0\SearchUI.exe")
		{
			Stop-Process -Name 'SearchUI';
			Set-ItemOwner "$0\SearchUI.exe"
			Rename-Item "$0\SearchUI.exe" "$0\SearchUI.exe_BLOCK"
		}
	}


	function SetKeyboardProperties
	{
		[System.ComponentModel.Description(
			'Adjust keyboard settings to fix slow delays and repeat rates')]
		[CmdletBinding(HelpURI='cmd')] param()

		# Some vendors configure keyboards with a slow delay and repeat rate. This customizes those
		# values to be more responsive. Can be done manually via Keyboard Properties control panel
		$0 = 'HKCU:\Control Panel\Keyboard'
		Set-ItemProperty $0 -Name 'KeyboardDelay' -Value '1' -Force
		Set-ItemProperty $0 -Name 'KeyboardSpeed' -Value '28' -Force
	}


	function SecurePagefile
	{
		[System.ComponentModel.Description(
			'Configure Windows to delete pagefile when Windows is shut down')]
		[CmdletBinding(HelpURI='cmd')] param()

		# set to 1 to cause pagefile to be deleted upon shutdown
		$0 = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
		Set-ItemProperty $0 -Name 'ClearPageFileAtShutdown' -value 1 -Type DWord
	}


	function SetTimeZone
	{
		[System.ComponentModel.Description(
			'Set the Clock time zone to EST, good for new installs and VMs')]
		[CmdletBinding(HelpURI='cmd')] param()

		Write-Verbose 'setting time zone'
		tzutil /s 'Eastern Standard Time'
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

	if ($command)
	{
		InvokeCommand $command
		return
	}

	# choco, git, 7zip
	InstallTools

	# $home\Documents\WindowsPowerShell
	GetPowerShellProfile

	SetTimeZone
	SetExplorerProperties
	SetKeyboardProperties
	SetExtras
	EnableHyperVEnhancedMode
	DisableHomeGroups
	EnablePhotoViewer
	EnableRemoteDesktop
	RemoveCrapware
	SecurePagefile
	ScheduleTempCleanup

	# requires powershell profile scripts
	DisableZipFolders

	GetYellowCursors
	SetConsoleProperties
	CreateHeadlessPowerPlan
	FixAirpodConnectivity

	$line = New-Object String('*',80)
	Write-Host
	Write-Host $line -ForegroundColor Cyan
	Write-Host ' Reminders ...' -ForegroundColor Cyan
	Write-Host $line -ForegroundColor Cyan
	Write-Host
	Write-Host @'
- Customize Startup items by looking in "shell:startup" and "shell:common startup"
- Add an Explorer library folder "AppData" pointing to Local and Roaming
- Clear entries from Explorer "Quick access" folder (can't automate)
- Import dark theme ps1xml into PowerShell ISE
'@ -ForegroundColor Cyan

	Write-Host
	Write-Host 'Initialization compelte' -ForegroundColor Yellow
}
