<#


I tried! I really tried. Sigh...

This mostly works but if your current user is a member of a group with elevated privileges
then the Command always starts elevated. Appears it's not possible to start a non-elevated
process from a privileged account on Windows!



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
> Restart-App -Name outlook -Register -command 'C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE' `
   -User $env:username -Password $password -StartTime '2am' -Delay '02:00:00' 

For quick testing, use: -Delay '00:00:05' -StartTime (get-date).addseconds(5)
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
    [switch] $Unregister,
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
            try
            {
                # get the commandline from the process, strip off quotes
                $script:cmdline = (Get-CimInstance win32_process `
                    -filter ("ProcessID={0}" -f $process.id)).CommandLine.Replace('"', '')

                Log "... terminating process $Name running $cmdline"

                # terminating instead of graceful shutdown because can't connect using this:
                # GetActiveObject undefined in pwsh Core. Any other way to connect?
                #$outlook = [Runtime.Interopservices.Marshal]::GetActiveObject('Outlook.Application')
                #$outlook.Quit()

                $process.Kill()
                $process = $null

                Log "sleeping $($delay.ToString())"
                Start-Sleep -Duration $delay
            }
            catch
            {
                Log "*** error stopping $Name"
                Log "*** $($_)"
            }
    }
        else
        {
            Log "... $Name process not found"
        }
    }


    function Startup
    {
        Log "... starting $Name"

        $credfile = "C:\Users\$User\$Name`.xml"
        if (Test-Path $credfile)
        {
            try
            {
                $credential = Import-Clixml $credfile
                
                # TODO: Remove this line:
                #Remove-Item -Path $credfile -Force

                Log "... running as $($credential.Username) with provided credentials"

                if ($Arguments)
                {
                    Log "... starting -Command `"$Command`" -Arguments `"$Arguments`""
                    Invoke-Command -Credential $credential -ComputerName $env:ComputerName `
                        -ScriptBlock { & $Command $Arguments }
                }
                else
                {
                    Log "... starting -Command `"$Command`""

                    #runas /machine:x86 /trustlevel:0x20000 "C:\Windows\sysWOW64\cmd.exe /c `"$Command`""

                    # Invoke-Command -Credential $credential -ComputerName $env:ComputerName `
                    #     -ScriptBlock { & $Command }

                    Log '... started? elevated?'
                }
            }
            catch
            {
                Log "*** error starting $Name"
                Log "*** $($_)"
            }
        }
        else
        {
            Log "... could not file $credfile, aborting"
        }
    }


    function RegisterTask
    {
        $span = $delay.ToString()
        $cmd = "Restart-App -Name '$Name' -Command '$Command' -Arguments '$cargs' -User $User -delay '$span'"

        $trigger = New-ScheduledTaskTrigger -Daily -At $StartTime
        $action = New-ScheduledTaskAction -Execute 'pwsh' -Argument "-Command ""$cmd"""

        $task = Get-ScheduledTask -TaskName "Restart $Name" -ErrorAction:SilentlyContinue
        if ($task -eq $null)
        {
            Write-Host "... creating scheduled task 'Restart $Name'"

            $credential = New-Object PSCredential($User, $Password)
            $credential | Export-Clixml -Path "C:\Users\$User\$Name`.xml" -Force

            #$credential = (New-Object System.Management.Automation.PSCredential `
            #    -ArgumentList $User, $Password).GetNetworkCredential()

            $plainPwd = ($credential).GetNetworkCredential().Password

            Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Restart $Name" `
                -User $User -Password $plainPwd | Out-Null
        }
        else
        {
            Write-Host "... scheduled task 'Restart $Name' is already registered"
        }
    }


    function UnregisterTask
    {
        $taskname = "Restart $Name"
        $info = get-scheduledtaskinfo -taskname $taskName  -ErrorAction:SilentlyContinue
        if ($info)
        {
            Write-Host "... unregistering scheduled task '$taskName'"
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        else
        {
            Write-Host "... scheduled task '$taskName' is not found"
        }
    }


    function Log
    {
        param([string] $text)
        $text | Out-File -FilePath $LogFile -Append
    }
}
Process
{
    if ($Name -and $Unregister)
    {
        UnregisterTask
        return
    }

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

    $script:LogFile = Join-Path $env:TEMP 'restart-app.log'
    # reset the log file
    "starting at $(Get-Date)" | Out-File -FilePath $LogFile

    Shutdown
    Startup

    Log 'done'
}