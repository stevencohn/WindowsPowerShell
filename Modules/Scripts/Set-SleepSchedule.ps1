<#
.SYNOPSIS
Creates scheduled tasks to sleep and wake the computer at specified times.
Once registered, you can customize the task schedules using the Task Scheduler app
and editing the Scheduled Sleep and Scheduled Wake tasks.

.PARAMETER Clear
Removes the scheduled tasks to sleep and wake the computer.

.PARAMETER ClearTimers
Unsets the Allow Wake Timers flag on each power scheme.

.PARAMETER SleepTime
The time to go to sleep, specified as a 24-hour military time.

.PARAMETER WakeTime
The time to wake from sleep, specified as a 24-hour military time.

.DESCRIPTION
The "Allow Wake Timers" setting is enabled on each power scheme to allow the wake task
to wake up the computer at the specified time.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[Parameter(ParameterSetName = 'setters', Position = 0, Mandatory = $true)]
    [ValidatePattern('([01]?[0-9]|2[0-3]):[0-5][0-9]')]
    [string] $SleepTime,

	[Parameter(ParameterSetName = 'setters', Position = 1, Mandatory = $true)]
    [ValidatePattern('([01]?[0-9]|2[0-3]):[0-5][0-9]')]
    [string] $WakeTime,

    [Parameter(ParameterSetName = 'unsetters')]
    [switch] $Clear,

    [Parameter(ParameterSetName = 'unsetters')]
    [switch] $ClearTimers
)

Begin
{
    $Enabled = 1
    $Disabled = 0

    function GetPowerSchemesIDs
    {
        return ((powercfg.exe /list) | `
            Select-String 'power scheme guid' -List) | `
            foreach { $_.toString().split(' ') | `
            where { ($_.length -eq 36) -and ([guid]$_) } }
    }

    function GetWakeTimerSettingID
    {
        # GUID of Allow Wake Timers subgroup is a well-known value for all schemes
        # but query it from the active scheme rather than hard-coding just in case!
        ((powercfg.exe /q) | `
            Select-String '(Allow wake timers)').tostring().split(' ') | `
            where {($_.length -eq 36) -and ([guid]$_)}
    }

    function SetWakeTimers
    {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline)] $schemeID,
            $settingID,
            $abled
        )

        Write-Host "... configuring Allow Waker Timers ($abled) for scheme $schemeID" -ForegroundColor DarkGray
        foreach ($args in (
            "/SETDCVALUEINDEX $schemeID SUB_SLEEP $settingID $abled",    # battery
            "/SETACVALUEINDEX $schemeID SUB_SLEEP $settingID $abled"))   # plugged in
        {
            Start-Process powercfg.exe -ArgumentList $args -Wait -Verb runas -WindowStyle Hidden
        }
    }

    function ClearUnattendedTimeout
    {
        # System unattended timeout is a hidden Advanced Power option that can be made visible by
        # changing its Attribute property from 1 to 2 under 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0
        # This function will not make that visible but will set each scheme to never sleep
        # Requires a logout/login or reboot to apply
        #
        # Seems this is required when the computer wakes and then you RDP to it, it doesn't
        # consider the RDP session as "activity" so will interrupt you and go to sleep anyway!
        # This prevents that.
        #
        $root = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings'
        $transitionsKey = '238C9FA8-0AAD-41ED-83F4-97BE242C8F20'
        $idleTimeoutKey = '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'
        Get-ChildItem "$root\$transitionsKey\$idleTimeoutKey\DefaultPowerSchemeValues" | `
        foreach {
            Set-ItemProperty $_.PSPath -Name 'AcSettingIndex' -Type DWord -Value 0
            Set-ItemProperty $_.PSPath -Name 'DcSettingIndex' -Type DWord -Value 0
        }
    }

    function RegisterSleepTask
    {
        # cannot use command "rundll32.exe 'Powrprof.dll,SetSuspendState Sleep'" because there
        # appears to be a bug in rundll32 that prevents the computer from waking up so instead
        # use the PSTools command "PSShutdown.exe -d -t 0"

        RegisterTask 'Scheduled Sleep' `
            (New-ScheduledTaskTrigger -Daily -At $SleepTime) `
		    (New-ScheduledTaskAction -Execute 'C:\tools\PSTools\psshutdown.exe' -Argument '-d -t 0') `
            (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false)
    }

    function RegisterWakeTask
    {
        RegisterTask 'Scheduled Wake' `
            (New-ScheduledTaskTrigger -Daily -At $WakeTime) `
            (New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-Command "Write-Host"') `
            (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false -WakeToRun)
    }


    function RegisterTask
    {
        param($name, $trigger, $action, $settings)
        $task = Get-ScheduledTask -TaskName "$name" -ErrorAction:SilentlyContinue
		if ($task -eq $null)
		{
            Write-Host "... creating '$name' task" -ForegroundColor DarkGray
            Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskName "$name" | Out-Null
		}
        else
        {
            Write-Host "... '$name' task is already registered" -ForegroundColor DarkGray
        }
    }

    function UnregisterTask
    {
        param($name)
        if (Get-ScheduledTask -TaskName $name -ErrorAction:silentlycontinue)
        {
            Write-Host "... unregistering $name task" -ForegroundColor DarkGray
            Unregister-ScheduledTask -TaskName $name -Confirm:$false
        }
        else
        {
            Write-Host "... $name task already unregistered" -ForegroundColor DarkGray
        }
    }
}
Process
{
    if ($PsCmdlet.ParameterSetName -eq "setters")
    {
        Write-Host "Configuring computer to sleep daily at $SleepTime and wake at $WakeTime"

        $settingID = GetWakeTimerSettingID
        GetPowerSchemesIDs | SetWakeTimers -settingID $settingID -abled $Enabled

        ClearUnattendedTimeout

        RegisterSleepTask
        RegisterWakeTask
    }
    elseif ($Clear)
    {
        Write-Host "Unregistering daily sleep and wake"

        UnregisterTask 'Scheduled Sleep'
        UnregisterTask 'Scheduled Wake'

        if ($ClearTimers)
        {
            $settingID = GetWakeTimerSettingID
            GetPowerSchemesIDs | SetWakeTimers -settingID $settingID -abled $Disabled
        }
    }
}
