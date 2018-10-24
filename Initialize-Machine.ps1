<#
.SYNOPSIS
Sets up a new machine with a custom configuration and PowerShell profile.

.PARAMETER Password
The password of the new local admin account to create.

.PARAMETER RemoveOneDrive
Remove OneDrive support; default is to keep OneDrive.

.PARAMETER Username
The username of the new local admin account to create.

.DESCRIPTION
This script will run in multiple stages under different accounts so it's easiest to
copy the script to $env:PROGRAMDATA and run from there in an administrative shell.

If creating a secondary administrator, this script will create the account and then
force a logout. After logging in as that secondary admin, continue running the script
and it will pick up where it left off. 

If skipping the secondary admin then the script only runs once in a single stage.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[string] $Username,
	[securestring] $Password,
	[switch] $RemoveOneDrive
)

Begin
{
	$stage = 0

	# needs to be in ProgramData because we're switching users between stages
	$stagefile = (Join-Path $env:PROGRAMDATA 'initialize-machine.stage')

	# Stage 0... - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	function NewPrimaryUser ()
	{
		Set-Content $stagefile '1' -Force
		$script:stage = 1

		if ($Username -or ($env:USERNAME -eq 'Administrator'))
		{
			$go = Read-Host 'Create local administrator? (y/n) [y]'
			if (($go -eq '') -or ($go.ToLower() -eq 'y'))
			{
				if (!$Username) { $Username = Read-Host 'Username' }
				if (!$Password) { $Password = Read-Host 'Password' -AsSecureString }

				# as initial user, create user layer1builder
				#$Password = ConvertTo-SecureString $Password -AsPlainText -Force
				New-LocalUser $Username -Password $Password -PasswordNeverExpires -Description "Build admin"
				Add-LocalGroupMember -Group Administrators -Member $Username

				Write-Host
				$go = Read-Host "Logout to log back in as $Username`? (y/n) [y]"
				if (($go -eq '') -or ($go.ToLower() -eq 'y'))
				{
					logoff; exit
				}
			}
		}
	}

	# Stage 1... - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	function SetTimeZone ()
	{
		Write-Verbose 'setting time zone'
		tzutil /s 'Eastern Standard Time'
	}

	function SetExplorerProperties ()
	{
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
		# taskbar small buttons
		Set-ItemProperty $0 -Name 'TaskbarSmallIcons' -Value 1 -Type DWord
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

		# hide recent shortcuts
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
		Set-ItemProperty $0 -Name 'ShowRecent' -Type DWord -Value 0
		Set-ItemProperty $0 -Name 'ShowFrequent' -Type DWord -Value 0
	
		# restart explorer.exe
		Stop-Process -Name explorer

		# set Dark mode
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
		New-ItemProperty $0 -Name 'AppsUseLightTheme' -Value 0 -Type dword -Force | Out-Null

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
	}

	function EnablePhotoViewer ()
	{
		Write-Verbose 'associated the good old Photo Viewer'

		# global preferences for all users
		$pvcmd = '%SystemRoot%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1'

		if (!(Test-Path 'HKCR:')) { New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null }
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
		Write-Verbose 'enabling Remote Desktop w/o Network Level Authentication...'
		$0 = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
		Set-ItemProperty $0 -Name 'fDenyTSConnections' -Type DWord -Value 0
		Set-ItemProperty "$0\WinStations\RDP-Tcp" -Name 'UserAuthentication' -Type DWord -Value 0
		Enable-NetFirewallRule -Name 'RemoteDesktop*'
	}

	function SetExtras ()
	{
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

		# DisableFeedback
		Write-Verbose 'disabling feedback'
		$0 = 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules'
		If (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'NumberOfSIUFInPeriod' -Type DWord -Value 0
		Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'DoNotShowFeedbackNotifications' -Type DWord -Value 1
		Disable-ScheduledTask -TaskName 'Microsoft\Windows\Feedback\Siuf\DmClient' -ErrorAction SilentlyContinue | Out-Null
		Disable-ScheduledTask -TaskName 'Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload' -ErrorAction SilentlyContinue | Out-Null

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

		# DisableCortana
		Write-Verbose "Disabling Cortana..."
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
		$0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
		if (!(Test-Path $0)) { New-Item -Path $0 -Force | Out-Null }
		Set-ItemProperty $0 -Name 'AllowCortana' -Type DWord -Value 0
	}

	function DisableHomeGroups ()
	{
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

	function RemoveCrapware ()
	{
		Write-Verbose 'removing crapware (some exceptions may appear)'
		$global:ProgressPreference = 'SilentlyContinue'

		# Microsoft crapware
		Get-AppxPackage *contactsupport* | Remove-AppxPackage

		@('3DBuilder', 'BingFinance', 'BingNews', 'BingSports', 'BingTranslator', 'BingWeather',
		'CommsPhone', 'Microsoft3DViewer', 'MicrosoftOfficeHub', 'MicrosoftPowerBIForWindows',
		'MicrosoftSolitaireCollection', 'MicrosoftStickyNotes', 'MinecraftUWP', 'NetworkSpeedTest',
		'Office.OneNote', 'Office.Sway', 'OneConnect', 'People', 'Print3D', 'SkypeApp', 'Wallet',
		'WindowsAlarms', 'WindowsCamera', 'WindowsCommunicationsapps', 'WindowsFeedbackHub', 'WindowsMaps',
		'WindowsPhone', 'Windows.Photos', 'WindowsSoundRecorder', 'ZuneMusic', 'ZuneVideo') | % `
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

	function RemoveOneDrive ()
	{
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
				if (!(Test-Path "HKCR:")) {
					New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
				}
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

	function InstallTools ()
	{
		Write-Verbose 'installing helper tools'

		# install chocolatey
		if ((Get-Command choco -ErrorAction:SilentlyContinue) -eq $null)
		{
			Set-ExecutionPolicy Bypass -Scope Process -Force
			Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
		}

		# install Git
		if ((Get-Command git -ErrorAction:SilentlyContinue) -eq $null)
		{
			choco install -y git
			# Git adds its path to the Machine PATH but not the Process PATH; copy it so we don't need to restart the shell
			$gitpath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine) -split ';' | ? { $_ -match 'Git\\cmd' }
			$env:Path = "${env:Path};$gitpath"
		}

		# install 7-Zip
		if ((Get-Command 7z -ErrorAction:SilentlyContinue) -eq $null)
		{
			choco install -y 7zip
		}

		# install Chrome
		if (!(Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'))
		{
			choco install -y googlechrome
		}
	}

	function GetPowerShellProfile ()
	{
		Write-Verbose 'fetching WindowsPowerShell environment'

		Push-Location $env:USERPROFILE\Documents
		git clone https://github.com/stevencohn/WindowsPowerShell.git
		Pop-Location
	}

	function GetYellowCursors ()
	{
		Write-Verbose 'enabling yellow mouse cursors'

		Push-Location $env:USERPROFILE\Documents
		git clone https://github.com/stevencohn/YellowCursors.git
		Push-Location YellowCursors
		.\Install.ps1
		Pop-Location
		Remove-Item YellowCursors -Recurse -Force
		Pop-Location
	}

	function SetConsoleProperties ()
	{
		Write-Verbose 'setting console properties'

		# customize console colors for CMD, PS, and ConEmu
		Set-Colors -Name Black -Color 0x292929 -Bgr -Background
		Set-Colors -Name DarkBlue -Color 0x916200 -Bgr
		Set-Colors -Name DarkGreen -Color 0x008000 -Bgr
		Set-Colors -Name DarkCyan -Color 0x808000 -Bgr
		Set-Colors -Name DarkRed -Color 0x000080 -Bgr
		Set-Colors -Name DarkMagenta -Color 0x800080 -Bgr
		Set-Colors -Name DarkYellow -Color 0x008080 -Bgr
		Set-Colors -Name Gray -Color 0xC0C0C0 -Bgr -Foreground
		Set-Colors -Name DarkGray -Color 0x808080 -Bgr
		Set-Colors -Name Blue -Color 0xFF8B17 -Bgr
		Set-Colors -Name Green -Color 0x00FF00 -Bgr
		Set-Colors -Name Cyan -Color 0xFFFF00 -Bgr
		Set-Colors -Name Red -Color 0x0000FF -Bgr
		Set-Colors -Name Magenta -Color 0x005EBB -Bgr
		Set-Colors -Name Yellow -Color 0x00FFFF -Bgr
		Set-Colors -Name White -Color 0xFFFFFF -Bgr

		# font
		Set-ItemProperty HKCU:\Console -Name 'FaceName' -Value 'Lucida Console' -Force
		Set-ItemProperty HKCU:\Console -Name 'FontSize' -Value 0x000c0000 -Force

		# history=100, rows=9999
		Set-ItemProperty HKCU:\Console -Name 'HistoryBufferSize' -Value 0x64 -Force
		Set-ItemProperty HKCU:\Console -Name 'ScreenBufferSize' -Value 0x2329008c -Force
	}
}
Process
{
	if (Test-Path $stagefile)
	{
		$stage = (Get-Content $stagefile) -as [int]
		if ($stage -eq $null) { $stage = 0 }
	}

	if ($stage -eq 0)
	{
		NewPrimaryUser
	}

	if ($stage -eq 1)
	{
		SetTimeZone
		SetExplorerProperties
		SetExtras
		DisableHomeGroups
		EnablePhotoViewer
		EnableRemoteDesktop
		RemoveCrapware

		if ($RemoveOneDrive) {
			RemoveOneDrive
		}

		InstallTools

		GetPowerShellProfile
		GetYellowCursors
		SetConsoleProperties

		Write-Host
		Write-Host 'Initialization compelte' -ForegroundColor Yellow

		Remove-Item $stagefile -Force -Confirm:$false
	}
}
