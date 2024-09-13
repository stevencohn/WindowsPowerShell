<#
.SYNOPSIS
Clear the contents of TEMP, Windows\TEMP, and LocalAppData\TEMP.

.PARAMETER Quiet
Suppress any output; default is to report amount of disk space recovered.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(
	SupportsShouldProcess = $true, 
	DefaultParameterSetName = 'clear')]

param(
	[switch] $Quiet,
	[Parameter(ParameterSetName = 'Install')]
	[switch] $Install = $false,
	[Parameter(ParameterSetName = 'Uninstall')]
	[switch] $Uninstall = $false
	)

Begin
{
	$script:taskName = 'Clear-Temp'


	function ClearFolder
	{
		param($path)

		if (!(Test-Path $path)) { return }

		$fils = [System.IO.Directory]::GetFiles($path, '*').Count
		$dirs = [System.IO.Directory]::GetDirectories($path, '*').Count

		Write-Verbose "... clearing $path"
		Remove-Item -Path "$path\*" -Force -Recurse -ErrorAction:SilentlyContinue

		$fc = $fils - [System.IO.Directory]::GetFiles($path, '*').Count
		$dc = $dirs - [System.IO.Directory]::GetDirectories($path, '*').Count

		$script:filCount += $fc
		$script:dirCount += $dc

		if (!$Quiet)
		{
			Write-Host "... removed $fc files, $dc directories from $path" -ForegroundColor DarkGray
		}
	}


	function RegisterTask
	{
		$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

		$pwsh = 'powershell.exe' #[System.Diagnostics.Process]::GetCurrentProcess().Path

		$log = Join-Path $env:USERPROFILE "task-logs\$taskName.log"
		$command = "Start-Transcript $log; & '${PSCommandPath}'"
		#$command = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))

		$action = New-ScheduledTaskAction -Execute $pwsh `
			-Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -Command ""${command}"""

		$trigger = New-ScheduledTaskTrigger -Daily -At 5am
		Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User $user -RunLevel Highest
	}
	
	function UnregisterTask
	{
		Unregister-ScheduledTask $taskName -Confirm:$false
	}
}
Process
{
    if ($PSCmdlet.ParameterSetName -eq 'Install')
    {
        RegisterTask
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'Uninstall')
    {
        UnregisterTask
        return
    }

	$used = (Get-PSDrive C).Used
	$script:filCount = 0
	$script:dirCount = 0

	ClearFolder 'C:\Temp'
	ClearFolder 'C:\Tmp'
	ClearFolder 'C:\Windows\Temp'
	ClearFolder (Join-Path $env:LocalAppData 'Temp')

	if (!$Quiet)
	{
		$disk = Get-PSDrive C | Select-Object Used, Free
		$pct = ($disk.Used / ($disk.Used + $disk.Free)) * 100
		$recovered = $used - $disk.Used
		Write-Host "... removed $filCount files, $dirCount directories"
		Write-Host ("... recovered {0:0.00} MB on drive C, {1:0.00}% used" -f ($recovered / 1024000), $pct)
	}
}
