#Requires -RunAsAdministrator
<#
.SYNOPSIS
Hides the bioiso.exe and ngciso.exe images.

.DESCRIPTION
Due to the way that my company has disabled alternate login methods like Windows Hello,
fingerprint, etc, while it appears that Hello is disabled, it isn't fully and bioiso.exe
and ngciso.exe will run and conume a full core. Every time you unlock the machine, an
additional BioIso.exe process will appear and consume another full core, eventually eating
up all CPU available on the machine!

.PARAMETER Install
Creates a schedueled task that will run this script at system startup

.PARAMETER Uninstall
Removes the scheduled task
#>
[CmdletBinding(DefaultParameterSetName = 'Fix')]
param(
	[Parameter(ParameterSetName = 'Install')]
	[switch] $Install = $false,
	[Parameter(ParameterSetName = 'Uninstall')]
	[switch] $Uninstall = $false
)

Begin
{
	$taskName = 'Disable-BioLogin'

	function DeleteNgcIosBackup
	{
		param($arc)
		$0 = "C:\Windows\WinSxS\$arc`_microsoft-windows-security-ngc-trustlet*\"
		if (Test-Path $0)
		{
			Get-ChildItem -Path $0 -filter NgcIso.exe -Recurse | % `
			{
				$name = $_.FullName
				Write-Host "... delete backup $name"
				Set-ItemOwner $name
				Remove-item -Path $name -Force -Confirm:$false
			}
		}
	}

	function HideOffender
	{
		param($offender)
		if (Test-Path $offender)
		{
			Write-Host "... hiding $offender"
			Set-ItemOwner $offender
			mv $offender "$offender`-hide" -Force -Confirm:$false
		}
	}

	function RegisterTask
	{
		$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

		$pwsh = 'powershell.exe' #[System.Diagnostics.Process]::GetCurrentProcess().Path

		$log = Join-Path $env:USERPROFILE "task-logs\$taskName.log"
		$command = "Start-Transcript $log; & '${PSCommandPath}'"
		#$command = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))

		$action = New-ScheduledTaskAction -Execute $pwsh `
			-Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -Command ""${command}"""

		$trigger = New-ScheduledTaskTrigger -AtStartup
		Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User $user -RunLevel Highest
	}
	

	function UnregisterTask
	{
		Unregister-ScheduledTask $taskName -Confirm:$false
	}
}
Process
{
	if ($PSCmdlet.ParameterSetName -eq 'Install')
	{
		RegisterTask
		return
	}

	if ($PSCmdlet.ParameterSetName -eq 'Uninstall')
	{
		UnregisterTask
		return
	}

	# hide them!

	# ngciso might get started first, so deal with it first to try to
	# catch it before it starts
	HideOffender "$($env:windir)\system32\ngciso.exe"
	HideOffender "$($env:windir)\system32\bioiso.exe"

	# delete WinSxS backup files
	DeleteNgcIosBackup 'amd64'
	DeleteNgcIosBackup 'wow64'
	DeleteNgcIosBackup 'x86'
}
