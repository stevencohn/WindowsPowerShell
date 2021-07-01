<#
.SYNOPSIS
Pins or unpins a target item to the Windows Taskbar

.PARAMETER Target
Path of the target item to pin to the Taskbar

.PARAMETER Unpin
If true then unpin target from the Taskbar

.NOTES
https://community.spiceworks.com/topic/2165665-pinning-taskbar-items-with-powershell-script
https://github.com/gunnarhaslinger/Add-or-Remove-Application-To-Windows-10-Taskbar/blob/master/TaskbarPinning.ps1

Handling Add-/Remove-TaskbarPinningApp can only be done by Processes named "explorer.exe"
Workaround to do this with Powershell: Make a copy of PowerShell to $env:TEMP\explorer.exe
#>

param(
    [parameter(Mandatory=$True, HelpMessage='Path of target item to pin to the Taskbar')]
    [ValidateNotNullOrEmpty()]
    [string] $Target,

    [Parameter(HelpMessage='If true then unpin target from the Taskbar')]
    [switch] $Unpin
)

Begin
{
    function RegisterShellHandlerVerb
    {
        Write-Verbose '... registering shell handler verb'
        $guid = (Get-ItemProperty ('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\' + `
            'Explorer\CommandStore\shell\Windows.taskbarpin')
            ).ExplorerCommandHandler

        $script:shellKey = (Get-Item 'HKCU:\SOFTWARE\Classes'
            ).OpenSubKey('*', $true
            ).CreateSubKey('shell', $true)

        $shellKey.CreateSubKey('{:}', $true).SetValue('ExplorerCommandHandler', $guid)
        Write-Verbose '... shell handler verb registered'
    }

    function UnregsisterShellHandlerVerb
    {
        if ($shellKey)
        {
            Write-Verbose '... unregistering shell handler verb'
            $shellKey.DeleteSubKeyTree('{:}', $false)
            if ($shellKey.SubKeyCount -eq 0 -and $shellKey.ValueCount -eq 0)
            {
                (Get-Item 'HKCU:\SOFTWARE\Classes'
                    ).OpenSubKey('*', $true
                    ).DeleteSubKey("shell")
            }
            Write-Verbose '... shell handler verb unregistered'
        }
    }

    function GetTaskbandPinMap
    {
        Write-Verbose '... getting Taskband pin map'
        # Taskband\FavoritesResolve is a binary value containing pinned items
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'
        $name = 'FavoritesResolve'

        # gets contents in ASCII format and filter out non-readable chars so -like will work
        return [Text.Encoding]::ASCII.GetString(
            (Get-ItemProperty -Path $key -Name $name | Select-Object -ExpandProperty $name)
            ) -Replace '[^\x20-\x2f^\x30-\x39\x41-\x5A\x61-\x7F]+', ''
    }

    function InvokeShellHandlerVerb
    {
        Write-Verbose '... invoking handler verb'
        $item = (Get-Item $Target)

        (New-Object -ComObject 'Shell.Application'
            ).Namespace($item.DirectoryName
            ).ParseName($item.Name
            ).InvokeVerb('{:}')

        Write-Verbose '... handler verb invoked'
    }
}
Process
{
    if (!(Test-Elevated))
    {
        Write-Warning 'must run from an elevated process'
    }

    if ((get-process | ? { $_.id -eq $pid }).ProcessName -ne 'explorer')
    {
        # presume current process is powershell
        $psh = (gcim win32_process | ? { $_.ProcessId -eq $pid }).CommandLine
        # restart this script, emulating the process name as 'explorer'
        Copy-Item $psh $env:TEMP\explorer.exe -Force

        $splat = @{ 
            Target = $Target
            Unpin = "`$$Unpin"
            Verbose = "`$$($PSCmdlet.MyInvocation.BoundParameters['Verbose'].IsPresent)"
        }

        . $env:TEMP\explorer.exe Set-PinTaskbar @splat
        return
    }

    if (Test-Path $Target)
    {
        $Target = (Resolve-Path $Target).Path
    }
    else
    {
        Write-Warning "$Target does not exist"
        return
    }

    RegisterShellHandlerVerb

    $map = GetTaskbandPinMap

    if ($Unpin)
    {
        # only unpin if item is pinned
        if ($map.Contains((Split-Path $Target -Leaf)))
        {
            Write-Verbose '... unpinning'
            InvokeShellHandlerVerb
        }
    }
    else
    {
        # only pin if item hasn't been pinned
        if (!$map.Contains((Split-Path $Target -Leaf)))
        {
            Write-Verbose '... pinning'
            InvokeShellHandlerVerb
        }
    }
}
End
{
    UnregsisterShellHandlerVerb
}