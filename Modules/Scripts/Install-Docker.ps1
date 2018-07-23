<#
.SYNOPSIS
Installs Docker for Windows, enabling Hyper-V as a prerequisite if not already installed.

.DESCRIPTION
This script might run in multiple stages. If Hyper-V is not installed, it will install it
and that will force a reboot. Then, after Docker is installed, you need to log out and log
in again in order to realize the account's membership in the docker-users group.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param ()

Begin
{
	$stage = 0
	$stagefile = (Join-Path $env:PROGRAMDATA 'install-docker.stage')

	function AddHyperV ()
	{
		if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -ne 'Enabled')
		{
			Write-Verbose 'enabling Hyper-V (will force reboot)'
			Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
		}
		else
		{
			# if already installed then skip SetHyperVProperties
			Set-Content $stagefile '2' -Force
			$script:stage = 2
		}
	}

	function SetHyperVProperties ()
	{
		if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -eq 'Enabled')
		{
			Write-Verbose 'setting Hyper-V properties'
			Set-VMHost -VirtualMachinePath 'C:\VMs' -VirtualHardDiskPath 'C:\VMs\Disks'
			Restart-Service vmms
		}
	}

	function AddDocker ()
	{
		Write-Verbose 'installing Docker for Windows'
		choco install docker-for-windows -y
		# may need to add other users to docker-users group
		#Add-LocalGroupMember -Group docker-users -Member layer1builder

		Write-Host 'Must logout and log in again to update Docker path'
		Write-Host 'After you log in and start Docker for first time, it will prompt'
		Write-Host 'to enable containerization and then force a reboot...'
	}
}
Process
{
	if ($null -ne (Get-Command Docker -ErrorAction 'SilentlyContinue'))
	{
		Write-Host 'Docker is already installed'
		return
	}

	if (Test-Path $stagefile)
	{
		$stage = (Get-Content $stagefile) -as [int]
		if ($stage -eq $null) { $stage = 0 }
	}

	if ($stage -eq 0)
	{
		# increment stage before enabling hyper-v because it will force reboot
		Set-Content $stagefile '1' -Force
		$stage = 1

		AddHyperV
	}

	if ($stage -eq 1)
	{
		Set-Content $stagefile '2' -Force
		$script:stage = 2

		SetHyperVProperties
	}

	if ($stage -eq 2)
	{
		AddDocker

		Write-Host
		Write-Host 'Docker setup complete; need to log out and log in again' -ForegroundColor Yellow

		Remove-Item $stagefile -Force -Confirm:$false
	}
}
