# PowerShell Scripts

These scripts are my custom profile scripts for PS command windows and for ISE including
a custom "Dark Selenitic" theme for ISE.

## How to install

This entire repo can be overlayed ontop of your Documents\WindowsPowerShell folder.

```powershell
Set-Location $env:USERPROFILE\Documents;
git clone https://github.com/stevencohn/WindowsPowerShell.git
```

If downloading the repo as a Zip file then you'll need to unblock all files:

```powershell
Get-ChildItem -Path "${env:USERPROFILE}\Documents\WindowsPowerShell" -Recurse | Unblock-File
```

To download just the [Initialize-Machine.ps1](#initmach) script:

```powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12';
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/stevencohn/WindowsPowerShell/master/Initialize-Machine.ps1' -OutFile C:\Initialize-Machine.ps1
```

Loosen up the execution policy:

```powershell
Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted -Force -Confirm:$false
```

## Commands
These scripts are located in the Modules\Scripts folder.

#### `Clear-Events` [-Quiet]
Clear all events from the Windows Event Log.

#### `ConvertFrom-Hex` -Hex v
Convert a Hex string into an integer value. If the string contains six
or eight characters then it is also interpreted as an ARGB value and each
component part is displayed.

#### `ConvertTo-Hex` -R r [-G g] [-B b]
Convert integer values to a Hex string. If one integer is specified then it is converted. If three integers are specified then they are assumed to be RGB values and combined into a single Hex string.

#### `Copy-Console` [-OutFile f] [-All] [-Rtf] [-Trim]
Copy the contents of the Powershell console window preserving color. Can be sent to an out file or pasted into Word or OneNote.

#### `Edit-PSProfile`
Run VSCode with ~Documents\WindowsPowerShell as root folder. Aliased to `ep`

#### `Enable-TrustedRemoting`
Enable PowerShell remoting and trusted hosts for the current machine,
typically run on a VM that will be used for automated tasks such as CI/CD.

#### `Get-Account` -Username u [-Domain d] [-SID]
Report the account information for the given username and optionally a specified domain.

![alt text](Images/get-account.png "Get-Account Example")

#### `Get-ChildItemColorized` -Dir d [-la]
Display a colorized directory listing along with total size. Aliased to `ls`

![alt text](Images/get-childitemcolorized.png "Get-ChildItemColorized Example")

#### `Get-Colors` [-All] [-Cmd] [-PS] [-ConEmu] [-Script]
Display the console colors for Command console, PowerShell console, and ConEmu consoles.

![alt text](Images/get-colors.png "Get-Colors Example")

#### `Get-DirSize` -Dir d [-la]
Report the size of all items in the specified folder. Used as a sub-routine of Get-ChildItemColorized.

#### `Get-DotNetVersion`
Get the versions of.NET Framework installations on the local computer.

#### `Get-Env` [-Name n] [-Value v]
Report environment variables in colorized categoties with optional search highlighting.

![alt text](Images/get-env.png "Get-Env Example")

#### `Get-Hosts`
Display the /etc/hosts file, colorized.

#### `Get-Installed` [-Outfile f]
Report all installed applications registered on the local system.

#### `Get-Network` [-Preferred] [-Addresses] [-Verbose]
Determines the most likely candidate for the active Internet-specific network adapter on this machine.  All other adpaters such as tunneling and loopbacks are ignored.  Only connected IP adapters are considered. Wifi aliases are shown.

![alt text](Images/get-network.png "Get-Network Example")

#### `Get-Path` [-Search s] [-Sort] [-Verbose]
Display the PATH environment variable as a list of strings rather than a single string and displays the source of each value defined in the Registry: Machine, User, or Process

![alt text](Images/get-path.png "Get-Path Example")

#### `Get-Performance`
Get and report performance metrics using the built-in WinSAT utility.

#### `Get-SpecialFolder` [-Folder f] [-All]
Return the translation of a SpecialFolder by name or show all SpecialFolders with optional search highlighting.

#### `Get-VMConfig` -Path p [-Json]
Returns a VM configuration object of the specified .vmcx VM configuration
file even if the VM is not attached to a Hyper-V server.

#### `Install-BuildTools` [-Force] [-Full] [-VsWhere]
Install minimal Microsoft build and test tools required for CI/CD.

#### `Install-Chocolatey` [-Upgrade]
Can be used on new machines to install Chocolately. If already installed then checks if it is outdated and prompts to update.

#### `Install-Docker`
Installs Docker for Windows, enabling Hyper-V as a prerequisite if not already installed.

#### `Invoke-NormalUser` -Command c
Execute a given command as a non-evelated context. Aliased to `nu`. 
Convenient when you need to run as a normal user from an elevated prompt.

#### `Invoke-SuperUser`
Open a new command prompt in elevated mode. Aliased to `su`. Special command for ConEmu emulator.

#### `Invoke-VsDevCmd`
Invoke the Visual Studio environment batch script. Aliased to `vs`

#### `New-CommandWrapper`
Sepcial internal function from PowerShell Cookbook.

#### `New-DriveMapping` -DriveLetter d -Path p [-SourceDriveLabel s] [-DriveLabel l] [-Reboot] [-Force]
Create a persistent mapping of a folder to a new drive letter. (persistent SUBST)

#### `New-Host` -IP a -Name n
Adds or updates an entry in the Windows hosts file

#### `New-VMClone` -Name n -Path p -Template t [-Checkpoint]
Create a new VM from a registered VM or an exported VM.

#### `Remove-DockerTrash` [-Volumes]
Prune unused docker containers and dangling images.

#### `Remove-DriveMapping` -DriveLetter d [-SourceDriveLabel s] [-Reboot] [-Force]
Remove a persistent mapping of a folder created by New-DriveMapping.

#### `Remove-Locked` -Name n
Remove a System-owned file or directory. Attempts multiple approaches to remove stubborn items.

#### `Repair-Path` [-Invalid] [-Yes]
Clean up the PATH environment variable, removing duplicates, empty values, and optionally paths that do not exist.

#### `Set-Colors` -Name n -Color c [-Bgr] [-Cmd] [-ConEmu] [-PS] [-Background] [-Foreground]
Set a custom value for the specified console color table entry in one or all of the Cmd, PowerShell, and ConEmu consoles. Also optionally set foreground or background color.

#### `Set-OutDefaultOverride`
(Internal) Helper function for Get-ChildItemColorized.

#### `Set-RegistryOwner` -Hive h -Key k [-Recurse]
Set full-access ownership of a specified Registry key.

#### `Show-ColorizedContent` -Filename f [-ExcludeLineNumbers]
Type the contents of a PowerShell script with syntax highlighting.

![alt text](Images/show-colorizedcontent.png "Show-ColorizedContent Example")

#### `Show-Docker` [-Ps] [-Containers] [-Images] [-Volumes]
Show containers and images in a single command.

![alt text](Images/show-docker.png "Show-Docker Example")

#### `Start-VMUntilReady` -Name n [-Restart] [-Restore]
Start the named VM, optionally restoring the latest snapshot, and waiting
until the OS provides a stable heartbeat.

#### `Test-Elevated` [-Action a ] [-Warn]
Determine if the current session is elevated and displays a warning message if not. Can be run without the warning message and simply return a boolean result.

#### `Test-RebootPending` [-Report]
Check the pending reboot status of the local computer.

<a name="initmach"></a>
## Initialize-Machine
This is a top-level script meant to be downloaded independently from this repo and run to configure and
initialize new machines. This script will download this repo to the current user's Document folder,
setting it up as the default PowerShell profile. Best to download it to and run from the root of C.
Run `Set-ExecutionPolicy RemoteSigned` prior to running if this is the first use of PowerShell.

   This script can optionally create a new local administrator so it runs in two phases:

   1. Log on as an administrator
   1. Download [Initialize-Machine.ps1](https://raw.githubusercontent.com/stevencohn/WindowsPowerShell/master/Initialize-Machine.ps1) to C:\Initialize-Machine.ps1
   1. Open an administrative PowerShell window
   1. PS> `Set-ExecutionPolicy RemoteSigned`
   1. PS> `cd C:\`
   1. PS> `.\Initialize-Machine.ps1 -User <new-admin-username>`
   1. ... Create new local administrator (y/n) [y]: `y`
   1. ... Password: *********
   1. ... Logout to log back in as &lt;new-admin-username> (y/n) [y]: `y`
   1. Log on as &lt;new-admin-username>
   1. Open an administrative PowerShell window
   1. PS> `cd C:\`
   1. PS> `.\Initialize-Machine.ps1 -Verbose`

   Finally, since this updates the PowerShell console colors, you can close and reopen the console to appreciate these fantastic new colors.

## Profiles

#### Microsoft.PowerShell_profile.ps1

This the primary PowerShell profile definition script, run whenenver a new PowerShell command
prompt is open or session is created. It defines aliases for some of the commands above. It also
invokes special utilities unique to my environment such as integration with ConEmu, WiLMa, 
Chocolatey, and setting the intial working directory.

##### Console Prompt Customization

The PowerShell command prompt is customized as follows:

* It is rendered in blue
* It indicates the current working directory prefaced with "PS" for example `PS D:\code>`
* If the console is elevated then the "PS" prefix is shown in red to highlight the fact that what do you, you do at your own risk!

  ![alt text](Images/ps-prompt.png "Colorized PS Prompt Example")


#### Microsoft.PowerShellISE_profile.ps1

This is the profile definition script fort the PowerShell ISE editor. It registers ISE add-ons
found in the Modules\Addons folder.

#### Microsoft.VSCode_profile.ps1

This is the profile definition script for the VSCode integrated PowerShell terminal.
It simply invokes the primary profile script above.

## Dark Selenitic Scheme

The `Dark Selenitic.StorableColorTheme.ps1xml` file defines the Dark Selenitic color scheme for ISE. The theme is also
defined by the Themes\PSTheme_Selenitic.ps1 script.
