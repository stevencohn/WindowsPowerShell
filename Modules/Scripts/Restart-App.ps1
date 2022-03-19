<#
.SYNOPSIS
Restart the named process. This can be used to restart applications such as Outlook on a nightly
basis. Apps such as this tend to have memory leaks or become unstable over time when dealing with
huge amounts of data on a very active system.

.PARAMETER Arguments
A string specifying the command line arguments to pass to Command on startup.

.PARAMETER Command
The command to use to start the application.
If not provided then try to use the command line of the existing process.
This parameter is required when using the -Register switch.

.PARAMETER Name
The name of the process to restart.

.PARAMETER Register
If specified then register a Task Scheduler entry to run daily at 2am, for example:
Restart-App Outlook 'C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE' '/recycle' -register

.PARAMETER GetCommand
If specified then report the command line of the specified running process. This value can be
used to specify the Command parameter when registering.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[Parameter(Mandatory = $true)] [string] $Name,
    [string] $Command,
    [string] $Arguments,
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
            $cmd = (gwmi win32_process -filter ("ProcessID={0}" -f $process.id)).CommandLine
            Write-Host "... found process $Name, ID $($process.ID), running $cmd"
        }
    }


    function Shutdown
    {
        $process = (Get-Process $Name -ErrorAction:SilentlyContinue)
        if ($process -ne $null)
        {
            # get the commandline from the process, strip off quotes
            $script:cmd = (gwmi win32_process -filter ("ProcessID={0}" -f $process.id)).CommandLine.Replace('"', '')
            Write-Host "... found process $Name running $cmd"

            # terminating instead of graceful shutdown because can't connect using this:
            # something funny about 32/64 or elevated process or just whatever
            #$outlook = [Runtime.Interopservices.Marshal]::GetActiveObject('Outlook.Application')

            Write-Host "... terminating process $Name"
            $process.Kill()
            $process = $null
            Start-Sleep -s 10
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
        $cmd = "Restart-App -Name '$Name' -Command '$Command' -Arguments '$Arguments'"

        $trigger = New-ScheduledTaskTrigger -Daily -At 2am;
		$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command ""$cmd"""

        $task = Get-ScheduledTask -TaskName "Restart $Name" -ErrorAction:SilentlyContinue
		if ($task -eq $null)
		{
            Write-Host "... creating scheduled task 'Restart $Name'"

            Register-ScheduledTask `
                -Action $action `
                -Trigger $trigger `
                -TaskName "Restart $Name" `
                -RunLevel Highest | Out-Null
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