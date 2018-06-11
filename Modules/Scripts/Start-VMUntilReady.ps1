<#
.SYNOPSIS
Starts the specified VM and waits until it is ready for use.

.PARAMETER Name
The name of the VM to start, default is cds-oracle

.PARAMETER Restart
If specified then restart running VM and wait until ready for use.

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

	[switch] $Restart,
	[switch] $Restore
	)

Begin
{
	function StartVM ()
	{
		$vm = (Get-VM $Name)
		if ($vm.State -ne 'Running')
		{
			if ($Restore)
			{
				$checkpoint = (Get-VMSnapshot $Name) | Sort -Descending CreationTime | Select -First 1
				if ($checkpoint)
				{
					Write-Verbose('Restoring snapshot {0}' -f $checkpoint.Name)
					$ProgressPreference = 'SilentlyContinue'
					$checkpoint | Restore-VMSnapshot -Confirm:$false
					$ProgressPreference = 'Continue'
				}
			}
	
			Write-Verbose "Starting VM $Name"
			$ProgressPreference = 'SilentlyContinue'
			$vm = (Start-VM -Name $Name)
			$ProgressPreference = 'Continue'
			WaitForHeartbeat
		}
		else
		{
			Write-Verbose "VM $Name already running"
		}
	}

	function WaitForHeartbeat ()
	{
		[double] $wait = 0
		While ((Get-VMIntegrationService -VMName $Name -Name 'Heartbeat').PrimaryStatusDescription -ne 'OK')
		{
			Start-Sleep -m 200
			$wait += 200
		}
		$wait = $wait / 1000
		Write-Verbose("VM stabilized after {0:0.00} seconds" -f $wait)
	}
}
Process
{
	if ($Restart -and ((Get-VM $Name).State -eq 'Running'))
	{
		Write-Verbose 'Stopping VM'
		$ProgressPreference = 'SilentlyContinue'
		Stop-VM $Name -Force
		$ProgressPreference = 'Continue'
		Start-Sleep -s 5
	}
	StartVM
}
