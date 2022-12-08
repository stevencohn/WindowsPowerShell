<#
.SYNOPSIS
List events related to system reboots.

.PARAMETER Uptime
Include uptime events in report; default is to hide these
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param([switch] $Uptime)

Begin
{
}
Process
{
    $ids = (41,1074,1076,6005,6006,6008,6009)

    if ($Uptime) {
        $ids += (6013)
    }

    $esc = [char]27
    $color = ''

    Get-EventLog System -Newest 10000 | `
        Where EventId -in $ids | `
        Sort-Object -Property TimeGenerated | `
        Format-Table `
            TimeGenerated,
            EventId,
            UserName,
            @{
                Label = 'Message'
                Expression =
                {
                    # use 'Get-Colors -all' command to fine DOS [esc color numbers
                    switch ($_.EventId)
                    {
                        #41 { $color = '31'; break } # dark red
                        #1074 { $color = '33'; break } # dark yellow
                        #1076 { $color = '33'; break } # dark yellow
                        6005 { $color = '94'; break } # blue
                        6006 { $color = '31'; break } # dark red
                        6008 { $color = '91'; break } # red
                        6009 { $color = '34'; break } # dark blue
                        6013 { $color = '90'; break } # dark gray
                        default { $color = '37' } # normal white
                    }
                    "$esc[$color`m$($_.Message)$esc[0m"
                }
             }`
            -AutoSize -Wrap
}

<#
Search for events here: https://kb.eventtracker.com/

41
The time service has been configured to use one or more input providers. However, none of the
input providers is still running. The time service has no source of accurate time. 

1074
The process %1 has initiated the %5 of computer %2 on behalf of user %7 for the following reason: %3 

1076
The reason supplied by user %6 for the last unexpected shutdown of this computer
is: %1 Reason Code: %2 Bug ID: %3 Bugcheck String: %4 Comment: %5

6005
The Event log service was started.

6006
The Event log service was stopped.

6008
The previous system shutdown at %1 on %2 was unexpected.

6009
Microsoft (R) Windows 2000 (R) <version> Service Pack <number> Uniprocessor Free.

6013
The system uptime is <number> seconds. 
#>
