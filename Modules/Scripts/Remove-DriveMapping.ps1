<#
.SYNOPSIS
Remove a persistent mapping of a folder.

.PARAMETER DriveLetter
The mapped drive letter to remove.

.PARAMETER Force
Force using SourceDriveLabel, provided DriverLetter is the last mapping
to the source drive.

.PARAMETER Reboot
If true then reboot system; default is true.

.PARAMETER SourceDriveLabel
New label to apply to the source drive; default it to retain the current label.
This is only applied if DriveLetter is the last mapping to the source drive.
#>

using namespace System.IO

[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[Parameter(Mandatory=$true, Position=0, HelpMessage='Drive letter must be a mapped drive')]
	[ValidateLength(1, 1)]
	[ValidatePattern('[A-Z]')]
	[ValidateScript({
		if ((Get-ItemPropertyValue "Registry::$DOSDevicesKey" -Name ('{0}:' -f $_) -ErrorAction 'SilentlyContinue') -eq $null) {
			Throw 'Drive letter not found or does not represent a mapped drive'
		}
		$true
	})]
	[string] $DriveLetter,

	[string] $SourceDriveLabel,

	[switch] $Reboot,
	[switch] $Force
	)

Begin
{
	$DriveIconsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons'
	$DOSDevicesKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices'

	function UnmapDriveLetter ()
	{
		# remove mapping
		if ($WhatIfPreference) {
			Write-Host "Remove-ItemProperty ""$DOSDevicesKey"" -Name ""${DriveLetter}:"" -Force" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "Remove-ItemProperty ""$DOSDevicesKey"" -Name ""${DriveLetter}:"" -Force"
			Remove-ItemProperty "$DOSDevicesKey" -Name "${DriveLetter}:" -Force | Out-Null
		}
		Write-Verbose 'removed persistent mapping'

		# remove volume label for mapped drive
		if ($WhatIfPreference) {
			Write-Host "Remove-Item ""$DriveIconsKey\$DriveLetter"" -Recurse -Force" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "Remove-Item ""$DriveIconsKey\$DriveLetter"" -Recurse -Force"
			if (Test-Path "$DriveIconsKey\$DriveLetter") {
				Remove-Item -Path "$DriveIconsKey\$DriveLetter" -Recurse -Force | Out-Null
			}
		}
		Write-Verbose 'removed mapped volume label'

		# remove volume label for source drive
		if ($WhatIfPreference) {
			Write-Host "Remove-Item ""$DriveIconsKey\$sourceLetter"" -Recurse -Force" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "Remove-Item ""$DriveIconsKey\$sourceLetter"" -Recurse -Force"
			if (Test-Path "$DriveIconsKey\$sourceLetter") {
				Remove-Item "$DriveIconsKey\$sourceLetter" -Recurse -Force | Out-Null
			}
		}
		Write-Verbose 'removed source drive volume label'

		# restore volume label
		if ($WhatIfPreference) {
			Write-Host "set label of $sourceLetter drive to $label" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "set label of $sourceLetter drive to $label"
			Set-Volume -DriveLetter $sourceLetter -NewFileSystemLabel $label
		}
		Write-Verbose 'set label of source drive'
	}
}
Process
{
	if (!$SourceDriveLabel -and (Test-Path "$DriveIconsKey\$DriveLetter")) {
		$SourceDriveLabel = (Get-ItemPropertyValue "$DriveIconsKey\$sourceLetter\DefaultLabel" -Name '(Default)' -ErrorAction 'SilentlyContinue')
	}

	if (!$SourceDriveLabel) {
		$SourceDriveLabel = if ($DriveLetter -eq ($env:HOMEDRIVE)[0]) { 'System' } else { 'Data' }
	}

	UnmapDriveLetter

	if ($Reboot -or !$PSBoundParameters.ContainsKey('Reboot'))
	{
		# must reboot in order for this to take effect
		if ($WhatIfPreference) {
			Write-Host 'Restart-Computer -Force -Timeout 0' -ForegroundColor DarkYellow
		} else {
			Restart-Computer -Force -Timeout 0
		}
	}
}
