# PowerShell Scripts

These scripts are my custom profile scripts for PS command windows and for ISE including
a custom "Dark Selenitic" theme for ISE.

## How to install

This entire repo can be overlayed ontop of your Documents\WindowsPowerShell folder.

## Commands
These scripts are located in the Modules\Scripts folder.

##### `Clear-Events`
Clear all events from the Windows Event Log.

#### `Confirm-Elevated`
Determine if the current session is elevated and displays a warning message if not. Can be run without the warning message and simply return a boolean result.

#### `ConvertTo-Hex`
Convert integer values to a Hex string. If one integer is specified then it is converted. If three integers are specified then they are assumed to be RGB values and combined into a single Hex string.

#### `Copy-Console`
Copy the contents of the Powershell console window preserving color. Can be sent to an out file or pasted into Word or OneNote.

#### `Edit-PSProfile`
Run VSCode with ~Documents\WindowsPowerShell as root folder. Aliased to `ep`

#### `Get-Account`
Report the account information for the given username and optionally a specified domain.

#### `Get-ChildItemColorized`
Display a colorized directory listing along with total size. Aliased to `ls`

#### `Get-ConsoleColors`
Display the console colors as defined in the Registry.

![alt text](Images/get-consolecolors.png "Get-ConsoleColors Example")

#### `Get-DirSize`
Report the size of all items in the specified folder. Used as a sub-routine of Get-ChildItemColorized.

#### `Get-Env`
Report environment variables in colorized categoties with optional search highlighting.

![alt text](Images/get-env.png "Get-Env Example")

#### `Get-Hosts`
Display the /etc/hosts file, colorized.

#### `Get-Installed`
Report all installed applications registered on the local system.

#### `Get-Network`
Determines the most likely candidate for the active Internet-specific network adapter on this machine.  All other adpaters such as tunneling and loopbacks are ignored.  Only connected IP adapters are considered. Wifi aliases are shown.

![alt text](Images/get-network.png "Get-Network Example")

#### `Get-Path`
Display the PATH environment variable as a list of strings rather than a single string and displays the source of each value defined in the Registry: Machine, User, or Process

![alt text](Images/get-path.png "Get-Path Example")

#### `Get-SpecialFolder`
Return the translation of a SpecialFolder by name or show all SpecialFolders with optional search highlighting.

#### `Invoke-SuperUser`
Open a new command prompt in elevated mode. Aliased to 'su'. Special command for ConEmu emulator.

#### `Invoke-VsDevCmd`
Invoke the Visual Studio environment batch script. Aliased to 'vs'

#### `New-CommandWrapper`
Sepcial internal function from PowerShell Cookbook.

#### `Remove-DockerTrash`
Prune unused docker containers and dangling images.

#### `Remove-Locked`
Remove a System-owned file or directory.

#### `Repair-Path`
Clean up the PATH environment variable, removing duplicates, empty values, and optionally paths that do not exist.

#### `Set-ConsoleColors`
Set a custom value for the specified Console color table entry.

#### `Set-OutDefaultOverride`
(Internal) Helper function for Get-ChildItemColorized.

#### `Show-ColorizedContent`
Type the contents of a PowerShell script with syntax highlighting.

#### `Show-Docker`
Show containers and images in a single command.

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
