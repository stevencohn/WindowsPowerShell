<#
.SYNOPSIS
Installs extra programs and features.

.PARAMETER Command
Invoke a single command from this script; default is to run all

.PARAMETER ListCommands
Show a list of all available commands

.DESCRIPTION
Install extra programs and features. Should be run after Initialize-Machine.ps1
and all updates are installed.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param (
    [parameter(Position=0)] $command,
	[switch] $ListCommands
    )

Begin
{
	function GetCommandList
	{
		Get-ChildItem function:\ | Where HelpUri -eq 'manualcmd' | select -expand Name | sort
	}


    function InvokeCommand
    {
        param($command)
		$fn = Get-ChildItem function:\ | where Name -eq $command
		if ($fn -and ($fn.HelpUri -eq 'manualcmd'))
        {
            Write-Host "... invoking command $($fn.Name)" -ForegroundColor Cyan
            Invoke-Expression $fn.Name
        }
        else
		{
            Write-Host "$command is not a recognized command" -ForegroundColor Yellow
            Write-Host 'Use -List argument to see all commands' -ForegroundColor DarkYellow
        }
    }


    function ChocoInstall
    {
        param($name)
        if ((choco list -l $name | Select-string "$name ").count -eq 0)
        {
            Write-Host
            Write-Host "---- Installing $name ---------------------------" -ForegroundColor Cyan
            choco install -y $name
        }
    }


    function InstallDockerDesktop
    {
		[CmdletBinding(HelpURI='manualcmd')] param()

        if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -ne 'Enabled')
        {
            Write-Host '... Hyper-V should be installed first' -ForegroundColor Cyan
            Write-Host '... Invoke the "InstallHyperV" command first and then run "InstallDockerDesktop"' -ForegroundColor Cyan
            Write-Host '... followed by "DisableCFG"' -ForegroundColor Cyan
        }

        ChocoInstall 'docker-desktop' # must add unsecure repos manually
    }


    function InstallHyperV
    {
		[CmdletBinding(HelpURI='manualcmd')] param()

        Write-Host '... Reboot will be required after installing Hyper-V' -ForegroundColor Cyan
        Write-Host '... After rebooting, run ".\Install-Programs.ps1 DisableCFG"' -ForegroundColor Cyan
        Write-Host
        Read-Host '... Press Enter to continue to set up Hyper-V'

        # ensure Hyper-V
        if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -ne 'Enabled') {
            # this will force a reboot
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
        }
    }


    function DisableCFG
    {
		[CmdletBinding(HelpURI='manualcmd')] param()

        # customize Hyper-V host
        Set-VMHost -VirtualMachinePath 'C:\VMs' -VirtualHardDiskPath 'C:\VMs\Disks'

        # disable Code Flow Guard (CFG) for vmcompute service
        Set-ProcessMitigation -Name 'C:\WINDOWS\System32\vmcompute.exe' -Disable CFG
        Set-ProcessMitigation -Name 'C:\WINDOWS\System32\vmcompute.exe' -Disable StrictCFG
        # restart service
        net start vmcompute
    }


    function InstallMacrium
    {
        ChocoInstall 'reflect-free' # just the installer to C:\tools\

        Write-Host '... Macrium download starting; it must be completed manually'
        Write-Host

        # This runs the downloader and leaves the dialog visible!
        & C:\tols\ReflectDL.exe
    }


    function RegisterWiLMa
    {
		[CmdletBinding(HelpURI='manualcmd')] param()
        # Register WindowsLayoutManager sheduled task to run as admin
        $trigger = New-ScheduledTaskTrigger -AtLogOn;
        $action = New-ScheduledTaskAction -Execute 'C:\Program Files\WiLMa\WindowsLayoutManager.exe';
        $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest;
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "WiLMa" -Principal $principal;
    }


    function InstallNodeJs
    {
		[CmdletBinding(HelpURI='manualcmd')] param()
        choco install -y nodejs --version 10.15.3
        # update session PATH so we can continue
        $npmpath = [Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';' | ? { $_ -match 'nodejs' }
        $env:PATH = (($env:PATH -split ';') -join ';') + ";$npmpath"
    }

    function InstallAngular
    {
		[CmdletBinding(HelpURI='manualcmd')] param()
        npm install -g @angular/cli@7.3.8
        npm install -g npm-check-updates
        npm install -g local-web-server
    }


    function InstallThings
    {
		[CmdletBinding(HelpURI='manualcmd')] param()
        ChocoInstall '7zip'
        ChocoInstall 'awscli'
        ChocoInstall 'git'
        ChocoInstall 'googlechrome'
        ChocoInstall 'greenshot'
        ChocoInstall 'linqpad'  # requires license (activation.txt)
        ChocoInstall 'mRemoteNG'
        ChocoInstall 'musicbee'
        ChocoInstall 'notepadplusplus'
        ChocoInstall 'npppluginmanager'
        ChocoInstall 'nuget.commandline'
        ChocoInstall 'paint.net'
        ChocoInstall 'robo3t'    
        ChocoInstall 'treesizefree'
        ChocoInstall 'vlc'
    }


    function InstallSourceTree
    {
		[CmdletBinding(HelpURI='manualcmd')] param()
        ChocoInstall 'sourcetree'

        'SourceTree: first time run...', `
        '- Log into choose "BitBucket" option and logon Atlassian online', `
        '- Enabled Advanced/"Configure automatic line endings"', `
        '- Do not create an SSH key' `
        | Write-Host -ForegroundColor Cyan
    }
    
    
    function InstallVisualStudio
    {
		# [CmdletBinding(HelpURI='manualcmd')] param()
        # # get the installer
        # $ProgressPreference = 'SilentlyContinue';
        # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12';
        # Invoke-WebRequest -Uri https://<someurl>/vs_Enterprise.exe -OutFile $home\Downloads\vs2019.exe;
        # Invoke-WebRequest -Uri https://<someurl>/.vsconfig -OutFile C:\.vsconfig;
        # # run the installer
        # & C:\vs2019.exe --config c:\.vsconfig;
        # # delete the installer
        # Remove-Item C:\vs2019.exe -Force -Confirm:$false

        # Write-Host '... Remember to update nuget package sources'
        # Write-Host
        # Write-Host '... Add these extensions manually:'
        # Write-Host '... Markdown Editor'
        # Write-Host '... Microsoft Visual Studio Installer Projects'
        # Write-Host '... VSColorOutput'
        # Write-Host '... SpecFlow for Visual Studio 2019'
        # Write-Host '... Editor Guidelines'
    }


    function InstallVSCode
    {
		[CmdletBinding(HelpURI='manualcmd')] param()
        ChocoInstall 'vscode'

        'Add these VSCode extensions manually:', `
        '- C#', `
        '- Color Picker', `
        '- Cucumber (Gherkin) Full Support', `
        '- Debugger for Chrome', `
        '- PowerShell', `
        '- TSLint', `
        '- vscode-icons', `
        '- XML Format' `
        | Write-Host -ForegroundColor Cyan
    }
}
Process
{
	if ($ListCommands)
	{
		GetCommandList
		return
	}

    if ($command)
	{
        InvokeCommand $command
        return
	}

    InstallThings
    InstallSourceTree

    RegisterWiLMa

    # Development...

    InstallNodeJs
    InstallAngular

    InstallVSCode

    #InstallVisualStudio

    InstallDockerDesktop

    'Manual installations:', `
    '- BareTail (there is a choco package but not pro version)', `
    '- BeyondCompare (there is a choco package but not for 4.0)', `
    '- ConEmu', `
    '- DateInTray', `
    '- OneMore OneNote add-in (https://github.com/stevencohn/OneMore/releases)', `
    '- S3Browser (https://s3browser.com/)', `
    '- WiLMa' `
    | Write-Host -ForegroundColor Cyan
}
