<#
.SYNOPSIS
Restart the named process. This can be used to restart applications such as Outlook on a nightly
basis. Apps such as this tend to have memory leaks or become unstable over time when dealing with
huge amounts of data on a very active system.

.PARAMETER Arguments
A string specifying the command line arguments to pass to Command on startup.

.PARAMETER Command
The command to start the application after the specified delay.
If not provided then try to use the command line of the named process.
This parameter is required when using the -Register switch.

.PARAMETER Delay
The amount of time to wait after stopping the application and until restarting
the application, specified as a TimeSpan "hh:mm:ss". Outlook will lock local pst data files,
preventing OneDrive from syncing them; this give OneDrive time to sync those files

.PARAMETER Name
The name of the process to restart.

.PARAMETER Password
A SecureString specifying the password for a named user. Must be specified with -User.

.PARAMETER User
The named user under which the scheduled task should run. Must be specified with -Password

.PARAMETER Register
Register a scheduled task to invoke the given command at a specified time.

.PARAMETER StartTime
The time of day to start the action. This can be any form accepted by the New-ScheduledTaskTrigger
command, so something like '2am', which is the default.

.PARAMETER GetCommand
If specified then report the command line of the specified running process. This value can be
used to specify the Command parameter when registering.

.EXAMPLE
❯ restart-app -Name outlook -GetCommand
... found process outlook, ID 3972, running "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"

To run the task in an elevated context:

> Restart-App -Name outlook -Register `
    -Command 'C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE' `
    -StartTime '2am' -Delay '02:00:00'

To run the task as a specific user:  important when restarting Outlook as it must run as
 the current user, otherwise it will run as admin and you can't click toast notification

> $password = ConvertTo-SecureString -AsPlainText <plainTextPassword>
> Restart-App -Name outlook -Register `
    -command 'C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE' `
    -StartTime '2am' -Delay '02:00:00' `
    -User '<username>' -Password $password
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
    [Parameter(Mandatory = $true)] [string] $Name,
    [string] $Command,
    [string] $Arguments,
    [string] $Delay = '02:00:00',
    [string] $StartTime = '2am',
    [string] $User,
    [System.Security.SecureString] $Password,
    [switch] $Register,
    [switch] $GetCommand
)

Begin
{
    function GetCommandLine
    {
        $process = (Get-Process $Name -ErrorAction:SilentlyContinue)
        if ($process -eq $null)
        {
            $script:cmd = $null
            Write-Host "... process $Name not found"
        }
        else
        {
            # get the commandline from the process, strip off quotes
            $cmd = (Get-CimInstance win32_process -filter ("ProcessID={0}" -f $process.id)).CommandLine
            Write-Host "... found process $Name, ID $($process.ID), running $cmd"
        }
    }


    function Shutdown
    {
        $process = (Get-Process $Name -ErrorAction:SilentlyContinue)
        if ($process -ne $null)
        {
            # get the commandline from the process, strip off quotes
            $script:cmd = (Get-CimInstance win32_process -filter ("ProcessID={0}" -f $process.id)).CommandLine.Replace('"', '')
            Write-Host "... found process $Name running $cmd"

            # terminating instead of graceful shutdown because can't connect using this:
            # something funny about 32/64 or elevated process or just whatever
            #$outlook = [Runtime.Interopservices.Marshal]::GetActiveObject('Outlook.Application')

            Write-Host "... terminating process $Name"
            $process.Kill()
            $process = $null
            Start-Sleep -s $delay
        }
        else
        {
            Write-Host "... $Name process not found"
        }
    }


    function Startup
    {
        if (!$cmd) { $cmd = $Command }
        if (!$cmd)
        {
            Write-Host "*** No command specified to start $Name" -ForegroundColor Yellow
            return
        }

        Write-Host "... starting $Name"
        Write-Host "... $cmd $Arguments"

        Invoke-Command -ScriptBlock { & $cmd $Arguments }
    }


    function RegisterTask
    {
        $span = $delay.ToString()
        $cmd = "Restart-App -Name '$Name' -Command '$Command' -Arguments '$Arguments' -delay '$span')"

        $trigger = New-ScheduledTaskTrigger -Daily -At 2am;
        $action = New-ScheduledTaskAction -Execute 'pwsh' -Argument "-Command ""$cmd"""

        $task = Get-ScheduledTask -TaskName "Restart $Name" -ErrorAction:SilentlyContinue
        if ($task -eq $null)
        {
            Write-Host "... creating scheduled task 'Restart $Name'"

            if ($User -and $Password)
            {
                $plainPwd = (New-Object System.Management.Automation.PSCredential `
                    -ArgumentList $User, $Password).GetNetworkCredential().Password

                Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Restart $Name" ` `
                    -User $User -Password $plainPwd ` | Out-Null
            }
            else
            {
                Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Restart $Name" `
                    -RunLevel Highest | Out-Null
            }
        }
        else
        {
            Write-Host "... scheduled task 'Restart $Name' is already registered"
        }
    }
}
Process
{
    if ($GetCommand)
    {
        GetCommandLine
        return
    }

    if (![TimeSpan]::TryParse($Delay, [ref]$delay))
    {
        Write-Host '*** Invalid Delay parameter, must be in TimeSpan format'
        return
    }

    if ($Register)
    {
        if (!$Command)
        {
            Write-Host '... Command argument is required when registering' -ForegroundColor Yellow
            return
        }

        RegisterTask
        return
    }

    Shutdown
    Startup
}