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
    $HeaderSize = 20
    $BlockSize = 1640
    $SettingOffset = 528

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
            $table.Add($offset.ToString(), $stream[$($offset)..$($offset + ($BlockSize - 1))])
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
    $stream = (Get-ItemProperty (Get-Item $TrayKey).PSPath).IconStreams

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

    foreach ($key in $table.Keys)
    {
        $item = $table[$key]

        $builder = New-Object System.Text.StringBuilder
        $item | % { [void]$builder.Append( ('{0:x2}' -f $_) ) }
        $hex = $builder.ToString()

        if ($hex.Contains($path))
        {
            Write-Host "$ProgramPath found in item at byte offset $key"
            $stream[$([Convert]::ToInt32($key) + $SettingOffset)] = $Setting

            $0 = (Get-Item $TrayKey).PSPath

            if (!$WhatIfPreference)
            {
                #Set-ItemProperty $0 -name IconStreams -value $stream
            }
            else
            {
                #Write-Host "Set-ItemProperty '$0' -name IconStreams -value $stream"
            }
        }
    }
}
