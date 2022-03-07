<#
.SYNOPSIS
Patch termsrv.dll to allow multiple concurrent RDP connections to this machine

.DESCRIPTION
When remoted to a machine, this will stop TermService which means you'll get kicked off your
remote session. The script should continue. You'll need to wait a minute for it to patch,
restart services, and complete before you can reconnect. When patching a local Hyper-V VM,
connect via the manager rather than RDP so you won't get disconnected.

.NOTES
Ensure that all "normal" users are members of the Remote Desktop user group
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
    [int] $MaxConnections = 2
)

Begin
{
    $script:termsrv = 'C:\Windows\System32\termsrv.dll'

    function PatchTermsrv
    {
        Write-Host 'reading termsrv.dll'
        if ($PSVersionTable.PSEdition.IndexOf('Core') -ge 0)
        {
            # PowerShell Core edition
            $bytes = Get-Content $termsrv -Raw -asByteStream
        }
        else
        {
            # PowerShell desktop edition
            $bytes = Get-Content $termsrv -Raw -Encoding Byte
        }

        Write-Host 'converting to byte array; one moment please'
        $text = $bytes.forEach('ToString', 'X2') -join ' '

        Write-Host 'paching termsrv.dll'

        # search for the 12-byte sequence to patch. This 12-byte sequence starts with a common
        # 8-byte prefix followed by a Windows version-specific 4-byte sequence
        # so we can search for the prefix and then replace the entire 12-byte sequence...

        $pattern = ([regex]'39 81 3C 06 00 00(\s\S\S){6}')
        $patch = 'B8 00 01 00 00 89 81 38 06 00 00 90'
        $match = Select-String -Pattern $pattern -InputObject $text
        if ($match -ne $null)
        {
            $text = $text -replace $pattern, $patch
        }
        elseif (Select-String -Pattern $patch -InputObject $text)
        {
            Write-Output '*** termsrv.dll is already patched'
            return $false
        }
        else
        { 
            Write-Output '*** pattern not found'
            return $false
        }

        # recreate byte array
        [byte[]] $bytes = -split $text -replace '^', '0x'

        Set-Content $env:TEMP\termsrv.dll.patched -Force -Encoding Byte -Value $bytes

        Write-Host 'validating patch'

        # output of fc.exe should contain exactly 12 lines...
        fc.exe /b $env:TEMP\termsrv.dll.patched $termsrv | Out-File $env:TEMP\termsrv.txt
        if ($LASTEXITCODE -eq 0)
        {
            Write-Host 'termsrv.dll was not patched'
            return $false
        }

        return (Get-Content $env:TEMP\termsrv.txt).Count -eq 12
    }

    function StopServices
    {
        Write-Host 'stopping services'
        Stop-Service UmRdpService -Force

        # termservice is harder to stop...
        sc.exe config TermService start= disabled
        $svcid = gwmi -Class Win32_Service -Filter "Name LIKE 'TermService'" | Select -ExpandProperty ProcessId
        taskkill /f /pid $svcid
    }

    function TakeOwnership
    {
        # save ACL and owner of termsrv.dll
        $script:savedAcl = Get-Acl $termsrv
        Write-Host "termsrv.dll owner: $($savedAcl.owner))"

        Write-Host 'creating termsrv backup'
        Copy-Item $termsrv "$termsrv.backup" -Force

        Write-Host 'taking ownership and granting full access'
        takeown /f $termsrv
        $owner = (Get-Acl $termsrv).Owner

        # /G grant :F full control to $owner myself 
        cmd /c "icacls $termsrv /Grant $($owner):F /C"
    }


    function RestoreOwnership
    {
        Write-Host 'restoring ownership'
        Set-Acl $termsrv $savedAcl
    }

    function StartServices
    {
        Write-Host 'starting services'
        sc.exe config TermService start= demand
        Start-Service TermService
        Start-Service UmRdpService
    }

    function SetGlobalPolicy
    {
        Write-Host 'setting Global Policy'

        # Global Policy settings from gpedit path:
        # Windows Components\Remote Desktop Services\Remote Desktop Session Host\Connections
        $0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'

        # Limit number of connections
        Set-ItemProperty $0 -Name 'MaxInstanceCount' -Type DWord -Value $MaxConnections

        # Restrict Remote Desktop Services users to a single Remote Desktop Services session
        Set-ItemProperty $0 -Name 'fSingleSessionPerUser' -Type DWord -Value 0
    }

    function EnableRemoteConnections
    {
        Write-Verbose 'enabling Remote Desktop w/o Network Level Authentication...'

        $0 = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
        Set-ItemProperty $0 -Name 'fDenyTSConnections' -Type DWord -Value 0
        Set-ItemProperty "$0\WinStations\RDP-Tcp" -Name 'UserAuthentication' -Type DWord -Value 0
        Enable-NetFirewallRule -Name 'RemoteDesktop*'
    }
}
Process
{
    # first create an validate a patched termsrv.dll

    if (PatchTermsrv)
    {
        # once created, apply the patch to the running system...

        Write-Host 'applying patch'

        StopServices
        TakeOwnership

        Write-Host 'ovewriting termsrv.dll'
        Copy-Item $env:TEMP\termsrv.dll.patched $termsrv -Force

        RestoreOwnership
        StartServices

        SetGlobalPolicy
        EnableRemoteConnections
    }
}
