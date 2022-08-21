<#
.SYNOPSIS
Upgrades all outdated chocolatey packages.

.PARAMETER all
Same as -yes

.PARAMETER yes
Adds the -yes parameter, accepting all updates without prompting
#>

param(
    [switch] $Yes,
    [switch] $All,
    [string] $WinTermPID
)

Begin
{
    $script:mswinterm = 'microsoft-windows-terminal'


    function CheckTerminalUpgrade
    {
        Write-Host "`n... running from Windows Terminal; please wait while checking status of $mswinterm" -ForegroundColor Cyan

        $available = choco outdated | where { $_ -match $mswinterm }
        if ($available)
        {
            Write-Host '... upgrade is available; this windows will close' -ForegroundColor Cyan
            $ans = Read-Host '... Upgrade now? (Y/N) [Y]'
            if ($ans -eq '' -or $ans -eq 'Y')
            {
                Start-Process -Verb RunAs `
                    -FilePath "$env:ComSpec" `
                    -ArgumentList '/c', 'start', "powershell.exe -f `"$PSCommandPath`" -WinTermPID $PID"
            }
        }
    }


    function UpgradeWindowsTerminal
    {
        Write-Host '... upgrading Microsoft Windows Terminal'
        Stop-Process $WinTermPID -Force
        Stop-Process -Name 'WindowsTerminal' -Force
        choco upgrade -y $mswinterm

        Read-Host "... done, press Enter to close this window"
    }
}
Process
{
    if ($WinTermPID)
    {
        UpgradeWindowsTerminal
        return
    }

    # note that choco pin command doesn't seem to work as advertised!

    $yesarg = ''
    if ($Yes -or $All) { $yesarg = '-y' }

    #choco upgrade $yesarg all --except="'linqpad,linqpad5,linqpad5.install'"
    if ($env:WT_SESSION)
    {
        choco upgrade $yesarg all --except="'$mswinterm'"

        CheckTerminalUpgrade
    }
    else
    {
        choco upgrade $yesarg all
    }
}
