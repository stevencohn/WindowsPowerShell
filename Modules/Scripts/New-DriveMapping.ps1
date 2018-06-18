<#
.SYNOPSIS
Create a persistent mapping of a folder to a new drive letter.

.PARAMETER DriveLabel
The volume label to apply to the new drive; default is to use the leaf folder
name indicated by Path.

.PARAMETER DriveLetter
The drive letter to map to Path. This drive letter must not be in use currently.

.PARAMETER Force
Force override of the source drive label when a mapping already exists on that drive
or force an override of the mapped drive letter if already mapped

.PARAMETER Path
Path to the folder to map to DriveLetter. This cannot be a root level folder (C:\)

.PARAMETER Reboot
If true then prompt to reboot system; default is true.

.PARAMETER SourceDriveLabel
New label to apply to the source drive; default it to retain the current label.
#>

using namespace System.IO

[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[Parameter(Mandatory=$true, Position=0, HelpMessage='Drive letter must not be a physical volume')]
	[ValidateLength(1, 1)]
	[ValidatePattern('[A-Z]')]
	[ValidateScript({
		if ((Get-Volume $_ -ErrorAction 'SilentlyContinue') -ne $null) {
			Throw 'DriveLetter cannot be a physical volume'
		}
		$true
	})]
	[string] $DriveLetter,

	[Parameter(Mandatory=$true, Position=1, HelpMessage='Path must specify a valid folder path')]
	[ValidateScript({
		if ((Test-Path $_) -and ((Split-Path $_ -leaf) -ne $_)) { return $true }
		Throw 'Path does not exist or is a root level folder'
	})]
	[string] $Path,

	[string] $SourceDriveLabel,
	[string] $DriveLabel,

	[switch] $Reboot,
	[switch] $Force
	)

Begin
{
	$DriveIconsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons'
	$DOSDevicesKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices'

	function MapFolderToDriveLetter ()
	{
		$sourceLetter = ([Path]::GetPathRoot($Path))[0]

		# In order for this to work, the drive containing the source folder must be given a
		# label in the Registry but that would conflict with the volume name so we must first
		# clear the volume name; this will be rectified below by setting it in the Registry.
		# Filter by drive letter and only if it still has a volume name
		if ($WhatIfPreference) {
			Write-Host "clear label of $sourceLetter drive" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "clear label of $sourceLetter drive"
			Get-Volume $sourceLetter | ? { $_.FileSystemLabel -ne '' } | Set-Volume -NewFileSystemLabel ''
		}
		Write-Verbose 'cleared label of source drive'

		# create new volume label for source drive if one doesn't already exist or if override
		if ($Force -or [String]::IsNullOrEmpty((Get-ItemPropertyValue `
			"$DriveIconsKey\$sourceLetter\DefaultLabel" -Name '(Default)' -ErrorAction 'SilentlyContinue')))
		{
			if ($WhatIfPreference) {
				Write-Host "Set-ItemProperty ""$DriveIconsKey\$sourceLetter\DefaultLabel"" -Name '(Default)' -Value $SourceDriveLabel" -ForegroundColor DarkYellow
			} else {
				Write-Verbose "Set-ItemProperty ""$DriveIconsKey\$sourceLetter\DefaultLabel"" -Name '(Default)' -Value $SourceDriveLabel"
				if (!(Test-Path "$DriveIconsKey\$sourceLette\DefaultLabel")) {
					New-Item "$DriveIconsKey\$sourceLetter\DefaultLabel" -Force | Out-Null
				}
				Set-ItemProperty "$DriveIconsKey\$sourceLetter\DefaultLabel" -Name '(Default)' -Value $SourceDriveLabel -Force | Out-Null
			}
			Write-Verbose 'set new volume label for source drive'
		}

		# create volume label for mapped drive
		if ($WhatIfPreference) {
			Write-Host "Set-ItemProperty ""$DriveIconsKey\$DriveLetter\DefaultLabel"" -Name '(Default)' -Value $DriveLabel" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "Set-ItemProperty ""$DriveIconsKey\$DriveLetter\DefaultLabel"" -Name '(Default)' -Value $DriveLabel"
			if (!(Test-Path "$DriveIconsKey\$DriveLetter\DefaultLabel")) {
				New-Item "$DriveIconsKey\$DriveLetter\DefaultLabel" -Force | Out-Null
			}
			Set-ItemProperty "$DriveIconsKey\$DriveLetter\DefaultLabel" -Name '(Default)' -Value $DriveLabel -Force | Out-Null
		}
		Write-Verbose 'set new volume label for mapped drive'

		# map virtual drive
		if ($WhatIfPreference) {
			Write-Host "Set-ItemProperty '$DOSDevicesKey' -Name '$DriveLetter`:' -Value '\??\$Path'" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "Set-ItemProperty '$DOSDevicesKey' -Name '$DriveLetter`:' -Value '\??\$Path'"
			Set-ItemProperty $DOSDevicesKey -Name "$DriveLetter`:" -Value "\??\$Path" -Force | Out-Null
		}
		Write-Verbose 'mapped persistent virtual drive'
	}
}
Process
{
    $DriveLetter = $DriveLetter.ToUpper()

	if (!$Force -and ((Get-ItemProperty $DOSDevicesKey | Select-Object "$DriveLetter`:" -Expand "$DriveLetter`:" -ErrorAction 'SilentlyContinue') -ne $null))
	{
		Throw 'Drive letter is already mapped; use -Force to override'
	}

	$Path = [Path]::GetFullPath($Path)
	if ($Path.EndsWith('\')) { $Path = $Path.Substring(0, $Path.Length - 1) }

	if (!$SourceDriveLabel)
	{
		$SourceDriveLabel = (Get-Volume (([Path]::GetPathRoot($Path))[0])).FileSystemLabel
		if ([String]::IsNullOrEmpty($SourceDriveLabel))
		{
			$SourceDriveLabel = (Get-ItemPropertyValue "$DriveIconsKey\$sourceLetter\DefaultLabel" -Name '(Default)' -ErrorAction 'SilentlyContinue')
		}
	}

	if (!$DriveLabel)
	{
		$DriveLabel = $Path | Split-Path -Leaf
	}

	MapFolderToDriveLetter

	if ($Reboot -or !$PSBoundParameters.ContainsKey('Reboot'))
	{
		# must reboot in order for this to take effect
		if ($WhatIfPreference) {
			Write-Host 'Restart-Computer -Force' -ForegroundColor DarkYellow
		} else {
			Restart-Computer -Force
		}
	}
}
