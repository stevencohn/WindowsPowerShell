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
Path to the folder to map to DriveLetter. This cannot be a root (C:\) or a top
level folder (C:\foo) - it must be at least a second level folder.

.PARAMETER SourceDriveLabel
New label to apply to the source drive; default it to retain the current label.
#>

using namespace System.IO

param (
	[Parameter(Mandatory=$true, HelpMessage='Drive letter must not be currently used')]
	[ValidateLength(1, 1)]
	[ValidatePattern('[A-Z]')]
	[ValidateScript({
		if (Get-Volume $_ -ErrorAction 'SilentlyContinue') {
			Throw 'Cannot reuse a physical drive letter'
		}
		$true
	})]
	[string] $DriveLetter,

	[Parameter(Mandatory=$true, HelpMessage='Path must specify a valid folder path')]
	[ValidateScript({
		if (Test-Path $_) {
			$lev=0; $p = $_; do { $p = split-path $p; $lev++ } while ($p)
			if ($lev -gt 2) { return $true }
		}
		Throw 'Path does not exist or is not at least a second level folder'
	})]
	[string] $Path,

	[string] $SourceDriveLabel,
	[string] $DriveLabel,

	[switch] $Force
	)

Begin
{
	$DriveIconsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons'
	$DOSDevicesKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices'

	function MapFolderToDriveLetter ()
	{
		$sourceLetter = ([Path]::GetPathRoot($Path))[0]

		# In order for this to work, the drive containing the target folder must be given a
		# label in the Registry but that would conflict with the volume name so we must first
		# clear the volume label; this will be rectified below by setting it in the Registry.
		# Filter by drive letter and only if it still have a volume name
		$filter = "deviceID='{0}:' and VolumeName<>''" -f $sourceLetter
		Get-CimInstance win32_logicaldisk -Filter $filter | Set-CimInstance -Property @{VolumeName=''}

		# create new volume label for source drive if one doesn't already exist or override
		if ($Force -or [String]::IsNullOrEmpty((Get-ItemPropertyValue `
			"$DriveIconsKey\$sourceLetter\DefaultLabel" -Name '(Default)' -ErrorAction 'SilentlyContinue')))
		{
			Set-ItemProperty "$DriveIconsKey\$sourceLetter\DefaultLabel" -Value $SourceDriveLabel
		}

		# create volume label for mapped drive
		Set-ItemProperty "$DriveIconsKey\$DriveLetter\DefaultLabel" -Value $DriveLabel

		# map virtual drive
		Set-ItemProperty $DOSDevicesKey -Name "${DriveLetter}:" -Value "\??\$Path"

		# restart (TODO: can we just restart Explorer?)
		Restart-Computer -Force -Timeout 0
	}
}
Process
{
	if (!$Force -and ((Get-ItemPropertyValue $DOSDevicesKey `
		-Name ('{0}:' -f $DriveLetter) -ErrorAction 'SilentlyContinue') -ne $null))
	{
		Throw 'Drive letter is already mapped; use -Force to override'
	}

	$Path = [Path]::GetFullPath($Path)

	if (!$SourceDriveLabel)
	{
		$SourceDriveLabel = (Get-Volume (([Path]::GetPathRoot($Path))[0])).FileSystemLabel
	}

	if (!$DriveLabel)
	{
		$DriveLabel = $Path | Split-Path -Leaf
	}

	MapFolderToDriveLetter
}
