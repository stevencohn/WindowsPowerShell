# PowerShell Scripts

This repo contains my custom PowerShell profile scripts.
It also contains scripts to automate the configuration of a new machine
and installation of common apps and tools that I frequently use.

## How to install

This entire repo can be overlayed ontop of your Documents\PowerShell folder.

As with all PowerShell scripts, you'll need to loosen up the execution policy on new machines.

```powershell
try{
Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force -Confirm:$false;
}catch{}
```

If starting from scratch on a fresh machine:

```powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12';
$0 = 'https://raw.githubusercontent.com/stevencohn/WindowsPowerShell/main'
Invoke-WebRequest -Uri "$0/common.ps1" -OutFile C:\common.ps1;
Invoke-WebRequest -Uri "$0/Initialize-Machine.ps1" -OutFile C:\Initialize-Machine.ps1
```
### Set PATH
Ensure that the scripts are discoverable by adding their folder to your System-wide environment
variable definitions:

`C:\Users\username\Documents\PowerShell\Modules\Scripts`

Then execute Initialize-Machine:

```powershell
. C:\Initialize-Machine.ps1 -Verbose
```

The script is re-entrant so can be run multiple times without a problem.

You can then delete these files since they exist in the Documents\WindowsPowerShell folder too:

```powershell
rm C:\common.ps1 -Force;
rm C:\Initialize-Machine.ps1 -Force
```

#### Alternatives

Initialize-Machine downloads the repo to Documents\WindowsPowerShell. If you already have Git
installed and would prefer to manually download the repo and run Initialize-Machine from there:

```powershell
Set-Location $home\Documents;
git clone https://github.com/stevencohn/WindowsPowerShell.git
```

Or if you download the repo as a Zip file, you'll need to unblock all files after unzipping:

```powershell
Get-ChildItem -Path "$home\Documents\WindowsPowerShell" -Recurse | Unblock-File
```

See also the [other configuration scripts below](#setup).

## Commands
These scripts are located in the Modules\Scripts folder.

#### [`Clear-Events`](Modules/Scripts/Clear-Events.ps1) [-Quiet]
Clear all events from the Windows Event Log.

#### [`Clear-Temp`](Modules/Scripts/Clear-Temp.ps1) [-Quiet]
Clear the contents of TEMP, Windows\TEMP, and LocalAppData\TEMP.

#### [`Connect-AwsLogin`](Modules/Scripts/Connect-AwsLogin.ps1) [-Profile] [-Account] [-Device] [-Code]
Sign in to AWS CLI using MFA for the configured profile of an IAM user.

#### [`ConvertFrom-BinHex`](Modules/Scripts/ConvertFrom-BinHex.ps1) -Hex v -Unicode
Convert a BinHex encoded string back to its original string value.

#### [`ConvertFrom-Hex`](Modules/Scripts/ConvertFrom-Hex.ps1) -Hex v
Convert a Hex string into an integer value. If the string contains six
or eight characters then it is also interpreted as an ARGB value and each
component part is displayed.

#### [`ConvertTo-Hex`](Modules/Scripts/ConvertTo-Hex.ps1) -R r [-G g] [-B b]
Convert integer values to a Hex string. If one integer is specified then it is converted. If three integers are specified then they are assumed to be RGB values and combined into a single Hex string.

#### [`ConvertTo-mp3`](Modules/Scripts/ConvertTo-mp3.ps1) -InputPath p [-Bitrate r] [-FullQuality] [-Info] [-Yes]
Primarily used to convert .m4a audio files to .mp3

#### [`Copy-Console`](Modules/Scripts/Copy-Console.ps1) [-OutFile f] [-All] [-Rtf] [-Trim]
Copy the contents of the Powershell console window preserving color. Can be sent to an out file or pasted into Word or OneNote.

#### [`Copy-Playlist`](Modules/Scripts/Copy-Playlist.ps1) -Playlist p -Target t -WhatIf
Copies all music files referenced by the given playlist to the specified location.
For example, this can be used to copy music in an .m3u playlist file to a USB thumbdrive.

#### [`Edit-Hosts`](Modules/Scripts/Edit-Hosts.ps1)
Open the hosts file in Notepad.

#### [`Enable-MultiRdp`](Modules/Scripts/Enable-MultiRdp.ps1) [-MaxConnection m]
Patch termsrv.dll to allow multiple concurrent RDP connections to this machine

#### [`Edit-Playlist`](Modules/Scripts/Edit-Playlist.ps1) -Replace r [-Path p] [-Type t]
Replace the path of all items in a playlist file to the current user's MyMusic path.

#### [`Edit-PSProfile`](Modules/Scripts/Edit-PSProfile.ps1)
Run VSCode with ~Documents\WindowsPowerShell as root folder. Aliased to `ep`

#### [`Enable-PersonalOneDrive`](Modules/Scripts/Enable-PersonalOneDrive.ps1)
Enable Personal OneDrive sync when both Business and Personal accounts are registered
on the local machine. Will indicate when either is account not available.

#### [`Enable-TrustedRemoting`](Modules/Scripts/Enable-TrustedRemoting.ps1)
Enable PowerShell remoting and trusted hosts for the current machine,
typically run on a VM that will be used for automated tasks such as CI/CD.

#### [`Get-Account`](Modules/Scripts/Get-Account.ps1) -Username u [-Domain d] [-SID] [-All]
Report the account information for the given username and optionally a specified domain.

![alt text](Images/get-account.png "Get-Account Example")

#### [`Get-ChildItemColorized`](Modules/Scripts/Get-ChildItemColorized.ps1) -Dir d [-la]
Display a colorized directory listing along with total size. Aliased to `ls`

![alt text](Images/get-childitemcolorized.png "Get-ChildItemColorized Example")

#### [`Get-Colors`](Modules/Scripts/Get-Colors.ps1) [-All] [-Cmd] [-PS] [-ConEmu] [-Script]
Display the console colors for Command console, PowerShell console, and ConEmu consoles.

![alt text](Images/get-colors.png "Get-Colors Example")

#### [`Get-CommandLine`](Modules/Scripts/Get-CommandLine.ps1) [-Name n] [-Only] [-ReturnValue] [-ShowSystem]
Report processes with their command lines, highlighting an optional search string

#### [`Get-Commits`](Modules/Scripts/Get-Commits.ps1) -Project p [-Branch b] [-Since yyyy-mm-dd] [-Last n] [-Raw] [-Graph]
Reports all commits for the given git repo after a specified date or within the last n days.

#### [`Get-DirSize`](Modules/Scripts/Get-DirSize.ps1) -Dir d [-la]
Report the size of all items in the specified folder. Used as a sub-routine of Get-ChildItemColorized.

#### [`Get-DotNetVersion`](Modules/Scripts/Get-DotNetVersion.ps1)
Get the versions of.NET Framework installations on the local computer.

#### [`Get-Env`](Modules/Scripts/Get-Env.ps1) [-Name n] [-Value v]
Report environment variables in colorized categoties with optional search highlighting.

![alt text](Images/get-env.png "Get-Env Example")

#### [`Get-Hosts`](Modules/Scripts/Get-Hosts.ps1)
Display the /etc/hosts file, colorized.

#### [`Get-Installed`](Modules/Scripts/Get-Installed.ps1) [-Store -Outfile f]
Report all installed applications registered on the local system, optionally including Store apps.

#### [`Get-Network`](Modules/Scripts/Get-Network.ps1) [-Preferred] [-Addresses] [-WiFi] [-Verbose]
Determines the most likely candidate for the active Internet-specific network adapter on this machine. All other adpaters such as tunneling and loopbacks are ignored. Only connected IP adapters are considered. Wifi aliases are shown.

![alt text](Images/get-network.png "Get-Network Example")

#### [`Get-ParentBranch`](Modules/Scripts/Get-ParentBranch.ps1)
Determine the name of the nearest parent branch of the current branch in the local Git repo.

#### [`Get-Path`](Modules/Scripts/Get-Path.ps1) [-Search s] [-Sort] [-Verbose]
Display the PATH environment variable as a list of strings rather than a single string and displays the source of each value defined in the Registry: Machine, User, or Process. Verbose mode dumps the User and System Paths as
stored in the Windows Registry.

![alt text](Images/get-path.png "Get-Path Example")

#### [`Get-Performance`](Modules/Scripts/Get-Performance.ps1)
Get and report performance metrics using the built-in WinSAT utility.

#### [`Get-Reboots`](Modules/Scripts/Get-Reboots.ps1) [-Uptime]
List Windows Event Log events related to system reboots.

#### [`Get-Scripts`](Modules/Scripts/Get-Scripts.ps1)
List all external scripts and their parameter names.

#### [`Get-Services`](Modules/Scripts/Get-Services.ps1) [-Name n] [-Running || -Stopped]
Get a list of services ordered by status and name. Aliased to `gs`

#### [`Get-SpecialFolder`](Modules/Scripts/Get-SpecialFolder.ps1) [-Folder f] [-All]
Return the translation of a SpecialFolder by name or show all SpecialFolders with optional search highlighting.

#### [`Get-VMConfig`](Modules/Scripts/Get-VMConfig.ps1) -Path p [-Json]
Returns a VM configuration object of the specified .vmcx VM configuration
file even if the VM is not attached to a Hyper-V server.

#### [`Install-BuildTools`](Modules/Scripts/Install-BuildTools.ps1) [-Force] [-Full] [-VsWhere]
Install minimal Microsoft build and test tools required for CI/CD.

#### [`Install-Chocolatey`](Modules/Scripts/Install-Chocolatey.ps1) [-Upgrade]
Can be used on new machines to install Chocolately. If already installed then checks if it is outdated and prompts to update.

#### [`Install-Docker`](Modules/Scripts/Install-Docker.ps1)
Installs Docker for Windows, enabling Hyper-V as a prerequisite if not already installed.

#### [`Invoke-NormalUser`](Modules/Scripts/Invoke-NormalUser.ps1) -Command c
Execute a given command as a non-evelated context. Aliased to `nu`. 
Convenient when you need to run as a normal user from an elevated prompt.

#### [`Invoke-SuperUser`](Modules/Scripts/Invoke-SuperUser.ps1)
Open a new command prompt in elevated mode. Aliased to `su`. Special command for ConEmu emulator.

#### [`New-Administrator`](Modules/Scripts/New-Administrator.ps1) -Username -Password
Create a new local admin user.

#### [`New-CommandWrapper`](Modules/Scripts/New-CommandWrapper.ps1)
Sepcial internal function from PowerShell Cookbook.

#### [`New-DriveMapping`](Modules/Scripts/New-DriveMapping.ps1) -DriveLetter d -Path p [-SourceDriveLabel s] [-DriveLabel l] [-Reboot] [-Force]
Create a persistent mapping of a folder to a new drive letter. (persistent SUBST)

#### [`New-Host`](Modules/Scripts/New-Host.ps1) -IP a -Name n
Adds or updates an entry in the Windows hosts file

#### [`New-RunAsShortcut`](Modules/Scripts/New-RunAsShortcut.ps1) -LinkPath l -TargetPath t [-Arguments a]
Creates a new elevated shortcut (.lnk file) to a given target

#### [`New-VMClone`](Modules/Scripts/New-VMClone.ps1) -Name n -Path p -Template t [-Checkpoint]
Create a new VM from a registered VM or an exported VM.

#### [`PrettyPrint-File`](Modules/Scripts/PrettyPrint-File.ps1) -Path p [-Dedent] [-Overwrite]
Format or pretty-pretty JSON and XML files.

#### [`Remove-DockerTrash`](Modules/Scripts/Remove-DockerTrash.ps1) [-Volumes]
Prune unused docker containers and dangling images.

#### [`Remove-DriveMapping`](Modules/Scripts/Remove-DriveMapping.ps1) -DriveLetter d [-SourceDriveLabel s] [-Reboot] [-Force]
Remove a persistent mapping of a folder created by New-DriveMapping.

#### [`Remove-Locked`](Modules/Scripts/Remove-Locked.ps1) -Name n
Remove a System-owned file or directory. Attempts multiple approaches to remove stubborn items.

#### [`Repair-Path`](Modules/Scripts/Repair-Path.ps1) [-Yes]
Clean up the PATH environment variable, removing duplicates, empty values, invalid paths, repairs
variable substitutions, and moves paths between User and System paths appropriately.
Verbose mode dumps the User and System Paths as stored in the Windows Registry.

#### [`Restart-App`](Modules/Scripts/Restart-App.ps1) -Name [-Command [-Arguments]] [-Register] [-GetCommand]
Restart the named process. This can be used to restart applications such as Outlook on a nightly
basis. Apps such as this tend to have memory leaks or become unstable over time when dealing with
huge amounts of data on a very active system. The -Register switch creates a nightly automation task.

#### [`Restart-Bluetooth`](Modules/Scripts/Restart-Bluetooth.ps1) [-Show]
Restarts the Bluetooth radio device on the current machine. This is useful when the radio stops
communicating with a device such as a mouse. The alternative would be to reboot the system.

#### [`Set-Colors`](Modules/Scripts/Set-Colors.ps1) -Theme t | [-Name n -Color c [-Bgr] [-Background] [-Foreground]] [-Cmd] [-ConEmu] [-PS]
Set the color theme for command line consoles or set a specific named color.

#### [`Set-ItemOwner`](Modules/Scripts/Set-ItemOwner.ps1) -Path p [-Group g]
Set the ownership of an item - folder or file - to the specified user group.

#### [`Set-OutDefaultOverride`](Modules/Scripts/Set-OutDefaultOverride.ps1)
(Internal) Helper function for Get-ChildItemColorized.

#### [`Set-PinTaskbar`](Modules/Scripts/Set-PinTaskbar.ps1) -Target t [-Unpin]
Pins or unpins a target item to the Windows Taskbar (_currently broken!_)

#### [`Set-RegistryOwner`](Modules/Scripts/Set-RegistryOwner.ps1) -Hive h -Key k [-Recurse]
Set full-access ownership of a specified Registry key.

#### [`Set-SleepSchedule`](Modules/Scripts/Set-SleepSchedule.ps1) (-SleepTime -WakeTime) | (-Clear [-ClearTimers])
Creates scheduled tasks to sleep and wake the computer at specified times.

#### [`Set-VsDevEnv`](Modules/Scripts/Set-VsDevEnv.ps1)
Invoke the Visual Studio environment batch script. Aliased to `vs`

#### [`Show-ColorizedContent`](Modules/Scripts/Show-ColorizedContent.ps1) -Filename f [-ExcludeLineNumbers]
Type the contents of a PowerShell script with syntax highlighting.

![alt text](Images/show-colorizedcontent.png "Show-ColorizedContent Example")

#### [`Show-Docker`](Modules/Scripts/Show-Docker.ps1) [-Ps] [-Containers] [-Images] [-Volumes]
Show containers and images in a single command.

![alt text](Images/show-docker.png "Show-Docker Example")

#### [`Test-Elevated`](Modules/Scripts/Test-Elevated.ps1) [-Action a ] [-Warn]
Determine if the current session is elevated and displays a warning message if not.
Can be run without the warning message and simply return a boolean result.

#### [`Test-RebootPending`](Modules/Scripts/Test-RebootPending.ps1) [-Report]
Check the pending reboot status of the local computer.

#### [`Update-Choco`](Modules/Scripts/Update-Choco.ps1) [-All]
Upgrades all outdated chocolatey packages, including Windows Terminal from a Windows Terminal.

#### [`Update-Environment`](Modules/Scripts/Update-Environment.ps1)
Refresh the current session environment variables from the Registry by harvesting
from both the local machine and the current user hives.

#### [`Update-Gits`](Modules/Scripts/Update-Gits.ps1) [-Branch b] [-Project p] [-Reset]
Scan all sub-folders looking for .git directories and fetch/pull each to get latest code.

#### [`Update-Profile`](Modules/Scripts/Update-Profile.ps1)
Quick command line to pull latest source of this WindowsPowerShell repo from Github
and update the content in $home\Documents\WindowsPowerShell.

#### [`WaitFor-VM`](Modules/Scripts/WaitFor-VM.ps1) -Name n [-Restore]
Start the named VM, optionally restoring the latest snapshot, and waiting
until the OS provides a stable heartbeat.

<a name="setup"></a>

# Machine Setup and Configuration
Using the scripts below, a new machine can be configured and apps installed in under
30 minutes.

Run `Set-ExecutionPolicy RemoteSigned` prior to running if this is the first use of PowerShell.

The recommended sequence to run:

1. Initialize-Machine.ps1
1. Install-HyperV.ps1 (_will reboot_)
1. Install-Programs.ps1 (_might reboot_)
1. Install-Programs.ps1 -Developer -Extras
1. Install-VS.ps1
1. Install-VS.ps1 -Extensions
1. Install-VS.ps1 -Code

#### [`Initialize-Machine.ps1`](Initialize-Machine.ps1)
This is a top-level script meant to be downloaded independently from this repo and run to configure and
initialize new machines. This script will download this repo to the current user's Document folder,
setting it up as the default PowerShell profile. Best to download it to and run from the root of C.

`Initialize-Machine.ps1 [-Command c] [-ListCommands]

   * _command_ - optional argument to run a single command, default is to run all commands
   * -ListCommands - display all available commands supported by this script

The Initialize-Machine script will download this repo into the MyDocuments folder, but
if you have OneDrive enabled then the MyDocuments folder may differ from $home\Documents.
So before initializing, you can create a junction point to MyDocuments using this command:

   1. `cd $home\Documents` 
   1. `cmd /c "mklink /j WindowsPowerShell $([Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell"`

Note there are two Initialie-Machine commands that are not run by default: DisableCortana and
DisableOneDrive. To disable either of these, use the -Command argument, e.g.

   `.\Initialize-Machine.ps1 -Command DisableCortana`

And since this updates the PowerShell console colors, you can close and reopen the console to
appreciate these fantastic new colors.

#### [`Install-HyperV.ps1`](Install-HyperV.ps1)
Automates the installation of Hyper-V on Windows 11 for either Professional or
Home editions. The script doesn't require any parameters but will prompt to reboot
the computer to complete the configuration.

#### [`Install-Programs.ps1`](Install-Programs.ps1)
Automates the installation of applications, development tools, and other utilities.
It's reentrant, skipping items already installed and installing items missing.

`.\Install-Programs.ps1 [-Command c] [-ListCommands] [-Developer] [-Extras] [-Verbose]`
 
   * _command_ - optional argument to run a single command, default is to run all commands
   * -ListCommands - display all available commands supported by this script
   * -Developer - install developer-specific tools and apps
   * -Extras - install extra utilities and apps
   * -Vebose - print extra information for each command

Hyper-V is required for a couple of command and warning will be displayed if it is not yet
available. Use Install-HyperV.ps1 to enable Hyper-V prior to running Install-Programs.

For Visual Studio and VSCode, use Install-VS.ps1.

Base applications:

   * Adobe Reader
   * BareTail Free (_installed to C:\tools_)
   * Greenshot
   * Macrium Reflect Free (_downloads installer to be run manually_)
   * mRemoteNG
   * Notepad++
   * SharpKeys
   * SysInternals procexp and procmon
   * Windows Terminal (_for Win10 machines_)

Developer applications:

   * .NET 6 SDK
   * Node.js (_specific version_)
   * Angular (_specific version_)
   * AWSCli
   * Docker Desktop
   * k9s
   * LINQPad
   * Nuget command line
   * Robot3T
   * S3Browser

Extra applications:

   * Audacity audio editor
   * DateInTray (_installed to C:\tools_; Win10 only)
   * Dopamine music player
   * Greenfish Icon Editor Pro
   * licecap
   * Paint.net
   * TreeSize Free
   * VLC
   * WiLMa (_installed to C:\tools_)
   * WmiExplorer (_installed to C:\tools_)

During the installation, hints and tips are shown highlighted in yellow and
instructions are highlighted in cyan. Some are import, such as how to continue
the manual installation of Macrium.

### Reminders shown after a full install

Macrium Reflect

   1. Double-click the Macrium Installer icon on the desktop after VS is installed
   1. Choose Free on first screen, then Home version, and no registration is necessary

Consider these manually installed apps:
- BeyondCompare (there is a choco package but not for 4.0)
- OneMore OneNote add-in (https://github.com/stevencohn/OneMore/releases)

#### [`Install-VS.ps1`](Install-VS.ps1)
Standalone script to install Visual Studio and its extensions or VSCode and its extensions.
The default is to install VS Professional.

`.\Install-VS.ps1 [-Code|Community|Professional|Enterprise|Extensions] [-Verbose]`

   * Visual Studio 2019 _and extensions_ (_professional or enterpise_)
   * VSCode _and extensions_

When installing VS, let it complete and then rerun this script with the -Extensions parameter
to install common extensions.

When installing VSCode (-Code), it will include extensions; there is no second step to do this.

# Profiles

### Microsoft.PowerShell_profile.ps1

This the primary PowerShell profile definition script, run whenenver a new PowerShell command
prompt is open or session is created. It defines aliases for some of the commands above. It also
invokes special utilities unique to my environment such as integration with ConEmu, WiLMa, 
Chocolatey, and setting the intial working directory.

#### Console Prompt Customization

The PowerShell command prompt is customized as follows:

   * It is rendered in blue
   * It indicates the current working directory prefaced with "PS" for example `PS D:\code>`
   * If the console is elevated then the "PS" prefix is shown in red to highlight the fact that what do you, you do at your own risk!

  ![alt text](Images/ps-prompt.png "Colorized PS Prompt Example")


### Microsoft.PowerShellISE_profile.ps1

This is the profile definition script fort the PowerShell ISE editor. It registers ISE add-ons
found in the Modules\Addons folder.

### Microsoft.VSCode_profile.ps1

This is the profile definition script for the VSCode integrated PowerShell terminal.
It simply invokes the primary profile script above.

# Dark Selenitic Scheme

The `Dark Selenitic.StorableColorTheme.ps1xml` file defines the Dark Selenitic color scheme for ISE. The theme is also
defined by the Themes\PSTheme_Selenitic.ps1 script.
