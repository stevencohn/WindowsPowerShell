<#
.SYNOPSIS
Initialize a new VM environment, optionally creating a secondary local admin account.

.PARAMETER EnableHyperV
Enable Hyper-V.

.PARAMETER Password
The password of the new local admin account to create.

.PARAMETER RemoveOneDrive
Remove OneDrive support; default is to keep OneDrive.

.PARAMETER Username
The username of the new local admin account to create.

.DESCRIPTION
This scripts runs in multiple stages. After a new local admin is created, the script
will log off the current session so you can log back in as that local admin account.
Later, the computer will need to be restarted after Hyper-V is enabled before
finializing the setup.
#>

param (
	[string] $Username,
	[securestring] $Password,
	[switch] $EnableHyperV,
	[switch] $RemoveOneDrive
)

Begin
{
	$stage = 0
	$stagefile = (Join-Path $env:APPDATA 'intialize-vm.stage')

	function NewPrimaryUser ()
	{
		$go = Read-Host 'Create local administrator? (y/n) [y]'
		if ($go.ToLower() -eq 'y')
		{
			if (!$Username) { $Username = Read-Host 'Username?' }
			if (!$Password) { $Password = Read-Host 'Password?' -AsSecureString }

			# as initial user, create user layer1builder
			#$Password = ConvertTo-SecureString $Password -AsPlainText -Force
			New-LocalUser $Username -Password $Password -Description "Build admin"
			Add-LocalGroupMember -Group Administrators -Member $Username

			Set-Content $stagefile '1' -Force

			Write-Host
			$go = Read-Host "Logout to log back in as $Username`? (y/n) [y]"
			if ($go.ToLower() -eq 'y')
			{
				logoff; exit
			}
		}
		else
		{
			Set-Content $stagefile '1' -Force
		}
	}

	function SetExecutionPolicy ()
	{
		Write-Verbose 'setting execution policy'
		Set-ExecutionPolicy RemoteSigned
	}

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

		# taskbar small buttons
		$0 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
		Set-ItemProperty $0 -Name 'TaskbarSmallIcons' -Value 1 -Type DWord
		# replace cmd prompt with PowerShell
		Set-ItemProperty $0 -Name 'DontUsePowerShellOnWinX' -Value 0 -Type DWord

		# hide taskbar search box
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
		Set-ItemProperty $0 -Name 'SearchboxTaskbarMode' -Type DWord -Value 0

		# show known file extensions - must restart Explorer.exe
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
		Set-ItemProperty $0 -Name 'HideFileExt' -Type DWord -Value 0

		# show hidden files
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
		Set-ItemProperty $0 -Name 'Hidden' -Type DWord -Value 1

		# restart explorer.exe
		Stop-Process -Name explorer

		# set Dark mode
		$0 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
		New-ItemProperty -Path $0 -Name 'AppsUseLightTheme' -Value 0 -Type dword -Force | Out-Null

		# set accent color
		$0 = 'HKCU:\Software\Microsoft\Windows\DWM'
		New-ItemProperty -Path $0 -Name 'ColorizationColor' -Value 0xc4767676 -Type dword -Force | Out-Null
		New-ItemProperty -Path $0 -Name 'ColorizationAfterglow' -Value 0xc4767676 -Type dword -Force | Out-Null
		New-ItemProperty -Path $0 -Name 'AccentColor' -Value 0xff767676 -Type dword -Force | Out-Null
	}

	function RemoveCrapware ()
	{
		Write-Verbose 'removing crapware (some exceptions may appear)'

		# Microsoft crapware
		Get-AppxPackage *commsphone* | Remove-AppxPackage
		Get-AppxPackage *contactsupport* | Remove-AppxPackage
		Get-AppxPackage *maps* | Remove-AppxPackage
		Get-AppxPackage *onenote* | Remove-AppxPackage
		Get-AppxPackage *weather* | Remove-AppxPackage
		Get-AppxPackage *xbox* | Remove-AppxPackage
		Get-AppxPackage "Microsoft.3DBuilder" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.BingFinance" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.BingNews" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.BingSports" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.BingTranslator" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.BingWeather" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.CommsPhone" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.Microsoft3DViewer" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.MicrosoftOfficeHub" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.MicrosoftPowerBIForWindows" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.MicrosoftSolitaireCollection" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.MicrosoftStickyNotes" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.MinecraftUWP" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.NetworkSpeedTest" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.Office.OneNote" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.Office.Sway" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.OneConnect" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.People" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.Print3D" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.SkypeApp" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.Wallet" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.WindowsAlarms" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.WindowsCamera" | Remove-AppxPackage
		Get-AppxPackage "microsoft.windowscommunicationsapps" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.WindowsFeedbackHub" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.WindowsMaps" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.WindowsPhone" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.Windows.Photos" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.WindowsSoundRecorder" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.ZuneMusic" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.ZuneVideo" | Remove-AppxPackage
		# Paint 3D
		Get-AppxPackage Microsoft.MSPaint | Remove-AppxPackage
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.3mf\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.bmp\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.fbx\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.gif\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.jfif\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.jpe\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.jpeg\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.jpg\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.png\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.tif\Shell\3D Edit' -Force -Recurse -Confirm:$false
		Remove-Item 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.tiff\Shell\3D Edit' -Force -Recurse -Confirm:$false
		# third party crap
		Get-AppxPackage "2414FC7A.Viber" | Remove-AppxPackage
		Get-AppxPackage "41038Axilesoft.ACGMediaPlayer" | Remove-AppxPackage
		Get-AppxPackage "46928bounde.EclipseManager" | Remove-AppxPackage
		Get-AppxPackage "4DF9E0F8.Netflix" | Remove-AppxPackage
		Get-AppxPackage "64885BlueEdge.OneCalendar" | Remove-AppxPackage
		Get-AppxPackage "7EE7776C.LinkedInforWindows" | Remove-AppxPackage
		Get-AppxPackage "828B5831.HiddenCityMysteryofShadows" | Remove-AppxPackage
		Get-AppxPackage "89006A2E.AutodeskSketchBook" | Remove-AppxPackage
		Get-AppxPackage "9E2F88E3.Twitter" | Remove-AppxPackage
		Get-AppxPackage "A278AB0D.DisneyMagicKingdoms" | Remove-AppxPackage
		Get-AppxPackage "A278AB0D.MarchofEmpires" | Remove-AppxPackage
		Get-AppxPackage "ActiproSoftwareLLC.562882FEEB491" | Remove-AppxPackage
		Get-AppxPackage "AdobeSystemsIncorporated.AdobePhotoshopExpress" | Remove-AppxPackage
		Get-AppxPackage "CAF9E577.Plex" | Remove-AppxPackage
		Get-AppxPackage "D52A8D61.FarmVille2CountryEscape" | Remove-AppxPackage
		Get-AppxPackage "D5EA27B7.Duolingo-LearnLanguagesforFree" | Remove-AppxPackage
		Get-AppxPackage "DB6EA5DB.CyberLinkMediaSuiteEssentials" | Remove-AppxPackage
		Get-AppxPackage "DolbyLaboratories.DolbyAccess" | Remove-AppxPackage
		Get-AppxPackage "Drawboard.DrawboardPDF" | Remove-AppxPackage
		Get-AppxPackage "E046963F.LenovoCompanion" | Remove-AppxPackage
		Get-AppxPackage "Facebook.Facebook" | Remove-AppxPackage
		Get-AppxPackage "flaregamesGmbH.RoyalRevolt2" | Remove-AppxPackage
		Get-AppxPackage "GAMELOFTSA.Asphalt8Airborne" | Remove-AppxPackage
		Get-AppxPackage "KeeperSecurityInc.Keeper" | Remove-AppxPackage
		Get-AppxPackage "king.com.BubbleWitch3Saga" | Remove-AppxPackage
		Get-AppxPackage "king.com.CandyCrushSodaSaga" | Remove-AppxPackage
		Get-AppxPackage "LenovoCorporation.LenovoID" | Remove-AppxPackage
		Get-AppxPackage "LenovoCorporation.LenovoSettings" | Remove-AppxPackage
		Get-AppxPackage "PandoraMediaInc.29680B314EFC2" | Remove-AppxPackage
		Get-AppxPackage "SpotifyAB.SpotifyMusic" | Remove-AppxPackage
		Get-AppxPackage "WinZipComputing.WinZipUniversal" | Remove-AppxPackage
		Get-AppxPackage "XINGAG.XING" | Remove-AppxPackage
		# Xbox
		Get-AppxPackage "Microsoft.XboxApp" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.XboxIdentityProvider" | Remove-AppxPackage -ErrorAction SilentlyContinue
		Get-AppxPackage "Microsoft.XboxSpeechToTextOverlay" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.XboxGameOverlay" | Remove-AppxPackage
		Get-AppxPackage "Microsoft.Xbox.TCUI" | Remove-AppxPackage
		Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0
		If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) {
			New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" | Out-Null
		}
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type DWord -Value 0
	}

	function UninstallOneDrive ()
	{
		Write-Verbose 'uninstalling OneDrive'

		Write-Output "Uninstalling OneDrive..."
		Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
		Start-Sleep -s 2
		$onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
		If (!(Test-Path $onedrive)) {
			$onedrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
		}
		Start-Process $onedrive "/uninstall" -NoNewWindow -Wait
		Start-Sleep -s 2
		Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
		Start-Sleep -s 2
		Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
		Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
		Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
		Remove-Item -Path "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue
		If (!(Test-Path "HKCR:")) {
			New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
		}
		Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
		Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
	}

	function InstallInstallTools ()
	{
		Write-Verbose 'installing helper tools'

		# install chocolatey
		Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

		# Git
		choco install git -y
	}

	function GetPowerShellProfile ()
	{
		Write-Verbose 'fetching WindowsPowerShell environment'

		Set-Location $env:USERPROFILE\Documents
		git clone https://github.com/stevencohn/WindowsPowerShell.git
	}

	function GetYellowCursors ()
	{
		Write-Verbose 'enabling yellow mouse cursors'

		Set-Location $env:USERPROFILE\Documents
		git clone https://github.com/stevencohn/YellowCursors.git
		Push-Location YellowCursors
		.\Install.ps1
		Pop-Location
		Remove-Item YellowCursors -Recurse -Force
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
		Set-ItemProperty -Path HKCU:\Console -Name 'FaceName' -Value 'Lucida Console' -Force
		Set-ItemProperty -Path HKCU:\Console -Name 'FontSize' -Value 0x000c0000 -Force

		# history=100, rows=9999
		Set-ItemProperty -Path HKCU:\Console -Name 'HistoryBufferSize' -Value 0x64 -Force
		Set-ItemProperty -Path HKCU:\Console -Name 'ScreenBufferSize' -Value 0x2329008c -Force
	}

	function EnableHyperV ()
	{
		# set stage before hyper-v forces a reboot
		Set-Content $stagefile '2' -Force

		Write-Verbose 'enabling Hyper-V (will force reboot)'
		Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V –All
	}

	function SetHyperVProperties ()
	{
		Write-Verbose 'setting Hyper-V properties'
		Set-VMHost -VirtualMachinePath 'C:\VMs' -VirtualHardDiskPath 'C:\VMs\Disks'
		Restart-Service vmms
	}

	function InstallDocker ()
	{
		Write-Verbose 'installing Docker for Windows'
		choco install docker-for-windows -y
		# may need to add other users to docker-users group
		#Add-LocalGroupMember -Group docker-users -Member layer1builder
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
		NewLocalUser
	}

	if ($stage -eq 1)
	{
		SetExecutionPolicy
		SetTimeZone
		SetExplorerProperties
		UninstallCrapware

		if ($RemoveOneDrive) {
			UninstallOneDrive
		}

		InstallInstallTools
		GetPowerShellProfile
		GetYellowCursors
		SetConsoleProperties

		Set-Content $stagefile '2' -Force

		if ($EnableHyperV) {
			EnableHyperV
		}
	}

	if ($stage -eq 2)
	{
		SetHyperVProperties
		InstallDocker

		Remove-Item $stagefile -Force -Confirm:$false
	}
}
