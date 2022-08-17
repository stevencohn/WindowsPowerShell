<#
.SYNOPSIS
Automates the installation of Hyper-V. Works on either Pro or Home editions

.DESCRIPTION
This will force an automatic reboot and will pick up where it left off to
complete the configuration.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]
param ()

Begin
{
	function CheckPrerequisites
	{
        # Elevated?
        if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()`
			).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
		{
			Write-Host
			Write-Host '... This script must be run from an elevated console' -ForegroundColor Yellow
			Write-Host '... Open an administrative PowerShell window and run again' -ForegroundColor Yellow
            return $false
		}

        # Windows 11?
        if ([int](Get-ItemPropertyValue -path $0 -name CurrentBuild) -ge 22000)
        {
            Write-Host
            Write-Host '... This script only applies to Windows 11' -ForegroundColor Yellow
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


	$proEdition = $null
	function ProEdition
	{
		if ($null -eq $proEdition)
		{
			$script:proEdition = (Get-WindowsEdition -online).Edition -eq 'Professional'
		}

		$proEdition
	}


    function AddFeaturePackages
    {
		'... Patching Home edition with Hyper-V feature packages' | `
			Write-Host -ForegroundColor Black -BackgroundColor Yellow

		(Get-ChildItem $env:SystemRoot\servicing\packages\*Hyper-V*.mum).Name | `
            foreach { 
                dism /online /norestart /add-package:"$($env:SystemRoot)\servicing\packages\$_"
            }
    }


    function EnableHyperV
	{
		'... Enabling Hyper-V; computer will reboot automatically' | `
			Write-Host -ForegroundColor Black -BackgroundColor Yellow

		if (ProEdition)
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

	if (!(ProEdition))
	{
   		AddFeaturePackages
	}

    EnableHyperV

	Write-Host
	Read-Host '... Press Enter for required reboot'
	Restart-Computer -Force
}
