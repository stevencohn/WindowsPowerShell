<#
.SYNOPSIS
Remove a persistent mapping of a folder created by New-DriveMapping.

.PARAMETER DriveLetter
The mapped drive letter to remove.

.PARAMETER Force
Force overriding volume label with SourceDriveLabel parameter, given that there
are no more associated mappings to that drive.

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
    	if ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices' | Select-Object "$_`:" -Expand "$_`:" -ErrorAction 'SilentlyContinue') -eq $null) {
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
			Write-Host "Remove-ItemProperty ""$DOSDevicesKey"" -Name ""$DriveLetter`:"" -Force" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "Remove-ItemProperty ""$DOSDevicesKey"" -Name ""$DriveLetter`:"" -Force"
			Remove-ItemProperty "$DOSDevicesKey" -Name "$DriveLetter`:" -Force | Out-Null
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

        # reset source drive label only if there are no more related mappings
        if (((Get-ItemProperty -Path $DOSDevicesKey).PSObject.Properties | ? `
            { $_.Name -match '^[A-Z]:$' -and $_.Value -match "^\\\?\?\\$sourceLetter`:\\" }).Count -eq 0)
        {
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
			    Write-Host "set label of $sourceLetter drive to $SourceDriveLabel" -ForegroundColor DarkYellow
		    } else {
			    Write-Verbose "set label of $sourceLetter drive to $SourceDriveLabel"
			    Set-Volume -DriveLetter $sourceLetter -NewFileSystemLabel $SourceDriveLabel
		    }
		    Write-Verbose 'set label of source drive'
        }
	}
}
Process
{
    $DriveLetter = $DriveLetter.ToUpper()

    $source = (Get-ItemProperty $DOSDevicesKey | Select-Object "$DriveLetter`:" -Expand "$DriveLetter`:" -ErrorAction 'SilentlyContinue')
    if ($source -eq $null)
    {
        Throw '$DriveLetter is not a mapped drive'
    }
    # format will be something like \??\C:\foobar
    $sourceLetter = $source[4]

	if (!$SourceDriveLabel -and (Test-Path "$DriveIconsKey\$DriveLetter")) {
		$SourceDriveLabel = (Get-ItemPropertyValue "$DriveIconsKey\$sourceLetter\DefaultLabel" -Name '(Default)' -ErrorAction 'SilentlyContinue')
	}

	if (!$SourceDriveLabel) {
		# if no label specified then choose a default label based on the system drive or a data drive
		$SourceDriveLabel = if ($sourceLetter -eq ($env:HOMEDRIVE)[0]) { 'System' } else { 'Data' }
	}

	UnmapDriveLetter

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
