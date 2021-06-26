<#
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
    [Parameter(
        Mandatory=$true,
        HelpMessage='Path of program')]
        [string] $ProgramPath,
    [Parameter(
        HelpMessage = '0=only show notifications, 1=hide, 2=show icon and notifications')]
        [ValidateScript( { if ($_ -lt 0 -or $_ -gt 2) { throw 'Invalid setting' } return $true })]
        [Int16] $Setting = 2
)

Begin
{
    $script:TrayKey = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify'

    function GetStreamData
    {
        param([byte[]] $streams)
        $builder = New-Object System.Text.StringBuilder
        
        # this line will ROT13 the data so you view/debug the ASCII contents of the stream
        #$streams | % { if ($_ -ge 32 -and $_ -le 125) { [void]$builder.Append( [char](Rot13 $_) ) } };

        $streams | % { [void]$builder.Append( ('{0:x2}' -f $_) ) }
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
    $streams = (Get-ItemProperty (Get-Item $TrayKey).PSPath).IconStreams

    $data = GetStreamData $streams

    $path = EncodeProgramPath $ProgramPath
    #Write-Host ( $path.Split('00') | ? { $_.Length -gt 0 } | % { [char](Rot13 ([Convert]::ToByte($_, 16))) } )

    if (-not $data.Contains($path))
    {
        Write-Warning "$ProgramPath not found. Programs are case sensitive."
        return
    }

    write-host 'Found!'
    return

    [byte[]] $header = @()
    $items = @{}
    for ($x = 0; $x -lt 20; $x++)
    {
        $header += $streams[$x]
    }

    for ($x = 0; $x -lt $(($streams.Count - 20) / 1640); $x++)
    {
        [byte[]] $item = @()
        $startingByte = 20 + ($x * 1640)
        $item += $streams[$($startingByte)..$($startingByte + 1639)]
        $items.Add($startingByte.ToString(), $item)
    }

    foreach ($key in $items.Keys)
    {
        $item = $items[$key]
        $strItem = ""
        $tempString = ""
        for ($x = 0; $x -le $item.Count; $x++)
        {
            $tempString = [Convert]::ToString($item[$x], 16)
            switch ($tempString.Length)
            {
                0 { $strItem += "00" }
                1 { $strItem += "0" + $tempString }
                2 { $strItem += $tempString }
            }
        }
        if ($strItem.Contains($strAppPath))
        {
            Write-Host Item Found with $ProgramPath in item starting with byte $key
            $streams[$([Convert]::ToInt32($key) + 528)] = $setting

            $0 = (Get-Item $TrayKey).PSPath

            if (!$WhatIfPreference)
            {
                Set-ItemProperty $0 -name IconStreams -value $streams
            }
            else
            {
                Write-Host "Set-ItemProperty '$0' -name IconStreams -value $streams"
            }
        }
    }
}
