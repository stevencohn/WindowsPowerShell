# PowerShell Scripts

These scripts are my custom profile scripts for PS command windows and for ISE including
a custom "Dark Selenitic" theme for ISE.

## How to install

This entire repo can be overlayed ontop of your Documents\WindowsPowerShell folder.

## Commands

### `Clear-Events`
Clear all events from the Windows Event Log.

### `Confirm-Elevated`
Determine if the current session is elevated and displays a warning message if not. Can be run without the warning message and simply return a boolean result.

### `ConvertTo-Hex`
Convert integer values to a Hex string. If one integer is specified then it is converted. If three integers are specified then they are assumed to be RGB values and combined into a single Hex string.

### `Copy-Console`
Copy the contents of the Powershell console window preserving color. Can be sent to an out file or pasted into Word or OneNote.

### `Edit-PSProfile`
Run VSCode with ~Documents\WindowsPowerShell as root folder. Aliased to `ep`

### `Get-Account`
Report the account information for the given username and optionally a specified domain.

### `Get-ChildItemColorized`
Display a colorized directory listing along with total size. Aliased to `ls`

### `Get-ConsoleColors`
Display the console colors as defined in the Registry.

### `Get-DirSize`
Report the size of all items in the specified folder. Used as a sub-routine of Get-ChildItemColorized.

### `Get-Env`
Report environment variables in colorized categoties with optional search highlighting.

### `Get-Hosts`
Display the /etc/hosts file, colorized.

### `Get-Installed`
Report all installed applications registered on the local system.

### `Get-Network`
Determines the most likely candidate for the active Internet-specific network adapter on this machine.  All other adpaters such as tunneling and loopbacks are ignored.  Only connected IP adapters are considered.

### `Get-Path`
Display the PATH environment variable as a list of strings rather than a single string and displays the source of each value defined in the Registry: Machine, User, or Process

### `Get-SpecialFolder`
Return the translation of a SpecialFolder by name or show all SpecialFolders with optional search highlighting.

### `Invoke-SuperUser`
Open a new command prompt in elevated mode. Aliased to 'su'. Special command for ConEmu emulator.

### `Invoke-VsDevCmd`
Invoke the Visual Studio environment batch script. Aliased to 'vs'

### `New-CommandWrapper`
Sepcial internal function from PowerShell Cookbook.

### `Remove-DockerTrash`
Prune unused docker containers and dangling images.

### `Remove-Locked`
Remove a System-owned file or directory.

### `Repair-Path`
Clean up the PATH environment variable, removing duplicates, empty values, and optionally paths that do not exist.

### `Set-ConsoleColors`
Set a custom value for the specified Console color table entry.

### `Set-OutDefaultOverride`
(Internal) Helper function for Get-ChildItemColorized.

### `Show-ColorizedContent`
Type the contents of a PowerShell script with syntax highlighting.

### `Show-Docker`
Show containers and images in a single command.

