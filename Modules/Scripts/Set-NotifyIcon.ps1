<#
.SYNOPSIS
Show or hides the notify icon of the specified program.

.PARAMETER ProgramPath
The full path of a program to find in the TrayNotify Registry item. The program must have
been run at least once to be recorded in the Registry.

.PARAMETER Hide
If specified as $true, hides the notify icon for the program. The default is to show the
icon and notifications.

.DESCRIPTION
Windows makes changes in memory and (over)writes changes to the Registry when explorer.exe
shuts down, so if changes are made, they get overwritten. So the best approach is to terminate
explorer.exe, run this script, and then start explorer.exe again.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
    [Parameter(Mandatory=$true, HelpMessage='Path of program')] [string] $ProgramPath,
    [Parameter(HelpMessage='Hide notify icon, default is to show')] [switch] $Hide
)

Begin
{
    $script:TrayNotifyKey = 'HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify'
    $script:HeaderSize = 20
    $script:BlockSize = 1640
    $script:SettingOffset = 528

    function GetStreamData
    {
        param([byte[]] $stream)
        $builder = New-Object System.Text.StringBuilder
        
        # this line will ROT13 the data so you view/debug the ASCII contents of the stream
        #$stream | % { if ($_ -ge 32 -and $_ -le 125) { [void]$builder.Append( [char](Rot13 $_) ) } };

        $stream | % { [void]$builder.Append( ('{0:x2}' -f $_) ) }
        return $builder.ToString()
    }

    function EncodeProgramPath
    {
        param([string] $path)

        $encoding = New-Object System.Text.UTF8Encoding
        $bytes = $encoding.GetBytes($path)

        $builder = New-Object System.Text.StringBuilder
        $bytes | % { [void]$builder.Append( ('{0:x2}00' -f (Rot13 $_)) ) }
        return $builder.ToString()
    }

    function BuildItemTable
    {
        param([byte[]] $stream)

        $table = @{}
        for ($x = 0; $x -lt $(($stream.Count - $HeaderSize) / $BlockSize); $x++)
        {
            $offset = $HeaderSize + ($x * $BlockSize)
            $table.Add($offset, $stream[$offset..($offset + ($BlockSize - 1))] )
        }
    
        return $table
    }

    function Rot13
    {
        param([byte] $byte)

            if ($byte -ge  65 -and $byte -le  77) { return $byte + 13 } # A..M
        elseif ($byte -ge  78 -and $byte -le  90) { return $byte - 13 } # N..Z
        elseif ($byte -ge  97 -and $byte -le 109) { return $byte + 13 } # a..m
        elseif ($byte -ge 110 -and $byte -le 122) { return $byte - 13 } # n..z
        
        return $byte
    }
}
Process
{
    # 0=only show notifications, 1=hide, 2=show icon and notifications
    $Setting = 2
    if ($Hide) { $Setting = 1 }

    $trayNotifyPath = (Get-Item $TrayNotifyKey).PSPath
    $stream = (Get-ItemProperty $trayNotifyPath).IconStreams

    $data = GetStreamData $stream
    #Write-Host $data

    $path = EncodeProgramPath $ProgramPath
    #Write-Host $path
    #Write-Host ( $path.Split('00') | ? { $_.Length -gt 0 } | % { [char](Rot13 ([Convert]::ToByte($_, 16))) } )

    if (-not $data.Contains($path))
    {
        Write-Warning "$ProgramPath not found. Programs are case sensitive."
        return
    }

    $table = BuildItemTable $stream
    #$table.Keys | % { Write-Host "$_`: " -ForegroundColor Yellow -NoNewline; Write-Host $table[$_] }

    # there may be multiple entries in the stream for each program, e.g. DateInTray will
    # have one entry for every icon, 1..31!!
    foreach ($key in $table.Keys)
    {
        $item = $table[$key]

        $builder = New-Object System.Text.StringBuilder
        $item | % { [void]$builder.Append( ('{0:x2}' -f $_) ) }
        $hex = $builder.ToString()

        if ($hex.Contains($path))
        {
            Write-Host "$ProgramPath found in item at byte offset $key"

            # change the setting!
            $stream[$key + $SettingOffset] = $Setting

            if (!$WhatIfPreference)
            {
                Set-ItemProperty $trayNotifyPath -name IconStreams -value $stream
            }
        }
    }
}
