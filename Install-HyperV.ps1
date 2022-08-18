<#
.SYNOPSIS
Automates the installation of Hyper-V. Works on either Pro or Home editions

.DESCRIPTION
This will force an automatic reboot and will pick up where it left off to
complete the configuration.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]
param (
	[switch] $Continuation
)

Begin
{
	. $PSScriptRoot\common.ps1

	function CheckPrerequisites
	{
        if (!(IsElevated))
		{
			Write-Host
			WriteWarn '... This script must be run from an elevated console'
			WriteWarn '... Open an administrative PowerShell window and run again'
            return $false
		}

        if (!(IsWindows11))
        {
            Write-Host
            WriteWarn '... This script only applies to Windows 11'
            return $false
        }

		# Already installed?
		if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -eq 'Enabled')
		{
            Write-Host
            Write-Host '... Hyper-V is ready for use' -ForegroundColor Green
            return $false
		}

		return $true
	}


    function AddFeaturePackages
    {
		Highlight '... Patching Home edition with Hyper-V feature packages'

		(Get-ChildItem $env:SystemRoot\servicing\packages\*Hyper-V*.mum).Name | `
            foreach { 
                dism /online /norestart /add-package:"$($env:SystemRoot)\servicing\packages\$_"
            }
    }


    function EnableHyperV
	{
		Highlight '... Enabling Hyper-V; will prompt to reboot to complete configuration'

		if (IsWindowsProEdition)
		{
			Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart
		}

		Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
	}
}
Process
{
	if (!(CheckPrerequisites))
	{
		return
	}

	if (IsWindowsHomeEdition)
	{
   		AddFeaturePackages
	}

	if ($Continue)
	{
		# customize Hyper-V host file locations
		Set-VMHost -VirtualMachinePath 'C:\VMs' -VirtualHardDiskPath 'C:\VMs\Disks'

		Write-Host
		WriteOK '... Hyper-V configuration is complete'
		return
	}

	EnableHyperV

	ForceStagedReboot
}
