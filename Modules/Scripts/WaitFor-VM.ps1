<#
.SYNOPSIS
Starts the specified VM and waits until it is ready for use.

.PARAMETER Name
The name of the VM to start.

.PARAMETER Restore
If specified then restore the latest snapshot of the VM.
#>

[CmdletBinding()]

param (
	[Parameter(Position=0, Mandatory=$true, HelpMessage='Enter the name of the VM to start')]
	[ValidateScript({
		if ([bool](Get-VM $_ -ErrorAction SilentlyContinue)) { $true } else {
			Throw "VM ""${_}"" not found"
		}
	})]
	[string] $Name,

	[switch] $Restore
	)

Begin
{
	function RestoreVM
	{
		$checkpoint = (Get-VMSnapshot $Name) | Sort -Descending CreationTime | Select -First 1
		if ($checkpoint)
		{
			Write-Host ('... restoring snapshot {0}' -f $checkpoint.Name)
			$global:ProgressPreference = 'SilentlyContinue'
			$checkpoint | Restore-VMSnapshot -Confirm:$false
			$global:ProgressPreference = 'Continue'
		}
	}
	function StartVM
	{
		$vm = (Get-VM $Name)
		if ($vm.State -ne 'Running')
		{
			Write-Host "... starting VM $Name"
			$global:ProgressPreference = 'SilentlyContinue'
			$vm = (Start-VM -Name $Name)
			$global:ProgressPreference = 'Continue'
		}
		else
		{
			Write-Host "... VM $Name already running"
		}
	}

	function WaitForHeartbeat
	{
		Write-Host '... detecting VM heartbeat'
		[double] $wait = 0
		While ((Get-VMIntegrationService -VMName $Name -Name 'Heartbeat').PrimaryStatusDescription -ne 'OK')
		{
			Start-Sleep -m 200
			$wait += 200
		}

		Write-Host '... detecting VM IP address'
		$ip = $null
		While ([String]::IsNullOrWhiteSpace($ip))
		{
			Start-Sleep -m 200
			$wait += 200
			$vm = Get-VM -Name $Name
			$ip = $vm.NetworkAdapters[0].IPAddresses | ? { $_.IndexOf('.') -gt 0 } | Select -First 1
		}

		$wait = $wait / 1000
		Write-Host ("... VM $Name ($ip) stabilized after {0:0.00} seconds" -f $wait)
	}
}
Process
{
	if ($Restore)
	{
		if ((Get-VM $Name).State -eq 'Running')
		{
			Write-Host '... stopping VM'
			$global:ProgressPreference = 'SilentlyContinue'
			Stop-VM $Name -TurnOff -Force
			$global:ProgressPreference = 'Continue'
		}

		RestoreVM
	}

	StartVM
	WaitForHeartbeat
}
