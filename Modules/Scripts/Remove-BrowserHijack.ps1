#Requires -RunAsAdministrator
<#
.SYNOPSIS
Removes corporate browser hijacking (default home page, broken Restore Pages feature, etc)

.DESCRIPTION
Removes group policy registry keys that are created by Waters IT in an attempt to waste
time by constantly directing users to a site they are not trying to visit.

.PARAMETER Install
Create a schedueled task that will periodically remove the hijack.
#>
[CmdletBinding(DefaultParameterSetName = 'Fix')]
param(
    [Parameter(ParameterSetName = 'Install')]
    [switch] $Install = $false,
    [Parameter(ParameterSetName = 'Uninstall')]
    [switch] $Uninstall = $false
)

Begin
{
    $taskName = 'Remove-BrowserHijack'

    function InstallHijack
    {
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        $pwsh = [System.Diagnostics.Process]::GetCurrentProcess().Path
        $command = "& '${PSCommandPath}'"
        $command = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))

        $action = New-ScheduledTaskAction -Execute $pwsh `
            -Argument "-NonInteractive -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand ${command}"

        $dailyTrigger = New-ScheduledTaskTrigger -Daily -At '7:00'
        $logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $user

        Register-ScheduledTask $taskName -Action $action -Trigger $dailyTrigger, $logonTrigger -User $user -RunLevel Highest
    }
	
    function UninstallHijack
    {
        Unregister-ScheduledTask $taskName
    }
}
Process
{
    if ($PSCmdlet.ParameterSetName -eq 'Install')
    {
        InstallHijack
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'Uninstall')
    {
        UninstallHijack
        return
    }

    # fix it now!

    # Chrome
    $0 = 'HKCU:\SOFTWARE\Policies\Google\Chrome'
    $p = @('HomePageLocation', 'RestoreOnStartup', 'ShowHomeButton')
    $p | foreach { if ((Get-ItemProperty $0).$_ -ne $null) { Remove-ItemProperty $0 $_ } }
    $0 = 'HKCU:\SOFTWARE\Policies\Google\Chrome\Recommended'
    $p | foreach { if ((Get-ItemProperty $0).$_ -ne $null) { Remove-ItemProperty $0 $_ } }

    $0 = 'HKCU:\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs'
    $p = $('HomepageLocation')
    $p | foreach { if ((Get-ItemProperty $0).$_ -ne $null) { Remove-ItemProperty $0 $_ } }
    $0 = 'HKCU:\SOFTWARE\Policies\Google\Chrome\Recommended\RestoreOnStartupURLs'
    $p | foreach { if ((Get-ItemProperty $0).$_ -ne $null) { Remove-ItemProperty $0 $_ } }

    # Edge
    $0 = 'HKCU:\SOFTWARE\Policies\Microsoft\Edge\Recommended'
    $p = @('HomepageLocation', 'RestoreOnStartup', 'ShowHomeButton', 'InternetExplorerIntegrationSiteList')
    $p | foreach { if ((Get-ItemProperty $0).$_ -ne $null) { Remove-ItemProperty $0 $_ } }

    $0 = 'HKCU:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Internet Settings'
    $p = 'ProvisionedHomePages'
    if ((Get-ItemProperty $0).$p -ne $null) { Remove-ItemProperty $0 $p }

    $0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    $p = 'HomepageLocation'
    if ((Get-ItemProperty $0).$p -ne $null) { Remove-ItemProperty $0 $p }

    $0 = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    $p = 'InternetExplorerIntegrationSiteList'
    if ((Get-ItemProperty $0).$p -ne $null) { Remove-ItemProperty $0 $p }

    # Firefox
    $0 = 'HKCU:\SOFTWARE\Policies\Mozilla\Firefox\Homepage'
    if (Test-Path $0) { Remove-Item $0 }
}
