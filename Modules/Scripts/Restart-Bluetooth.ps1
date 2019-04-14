<#
.SYNOPSIS
Restarts the Bluetooth radio device on the current machine. This is useful
when the radio stops communicating with a device such as a mouse. The
alternative would be to reboot the system.

.PARAMETER Show
Show the status of the Bluetooth radio.
#>

param(
	[switch] $Show
)

$device = Get-PnPDevice | ? { $_.Class -eq 'Bluetooth' -and $_.FriendlyName -match 'Radio' } | Select -First 1

if ($device)
{
	Write-Host
	Write-Host "... Found $($device.FriendlyName)" -ForegroundColor White

	if ($Show)
	{
		$device | Select *
	}
	else
	{
		Write-Host '... disabling' -ForegroundColor DarkGray
		$device | Disable-PnpDevice -Confirm:$false | Out-Null

		Write-Host '... enabling' -ForegroundColor DarkGray
		$device | Enable-PnpDevice -Confirm:$false | Out-Null
	}
}
else
{
	Write-Host '... Bluetooth radio not found' -ForegroundColor Yellow
}