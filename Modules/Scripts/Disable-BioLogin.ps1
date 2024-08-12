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

    function RegisterTask
    {
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        $pwsh = [System.Diagnostics.Process]::GetCurrentProcess().Path
        $command = "& '${PSCommandPath}'"
        $command = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))

        $action = New-ScheduledTaskAction -Execute $pwsh `
            -Argument "-NonInteractive -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand ${command}"

        $startupTrigger = New-ScheduledTaskTrigger -AtStartup

        Register-ScheduledTask $taskName -Action $action -Trigger $startupTrigger -User $user -RunLevel Highest
    }
	
    function UnregisterTask
    {
        Unregister-ScheduledTask $taskName
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
    $offender = "$($env:windir)\system32\ngciso.exe"
    if (Test-Path $offender)
    {
        Set-ItemOwner $offender
        mv $offender "$offender`-hide" -Force -Confirm:$false
    }

    $offender = "$($env:windir)\system32\bioiso.exe"
    if (Test-Path $offender)
    {
        Set-ItemOwner $offender
        mv $offender "$offender`-hide" -Force -Confirm:$false
    }
}
