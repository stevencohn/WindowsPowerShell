#*************************************************************************************************
# Microsoft.PowerShell_profile.ps1                                                    22 Jun 2013
#*************************************************************************************************

$modules = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) "WindowsPowerShell\Modules"
if (!$env:PSModulePath.Contains($modules)) { $env:PSModulePath = $modules + ";" + $env:PSModulePath }

Import-Module -Global -Name Addons.psd1

function AddMenuItem ($menu, $displayName, $action, $shortcut)
{
    $item = $menu | ? { $_.DisplayName.Equals($displayName) }
    if (!$item)
    {
        #Write-Host ... adding $displayName item
        $menu.Add($displayName, $action, $shortcut) | Out-Null
    }
    else
    {
        #Write-Host ... $displayName item already exists
    }
}

# Add-ons menu
$rootMenu = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus

# Add-ons\Editor menu
$editMenu = ($rootMenu | ? { $_.DisplayName.Equals("Editor") })
if (!$editMenu)
{
    $editMenu = $rootMenu.Add("Editor", $null, $null).SubMenus
    AddMenuItem $editMenu "Close file" { Close-CurrentFile } "Alt+X"
    AddMenuItem $editMenu "Copy colorized" { Copy-Colorized } "Alt+C"
    AddMenuItem $editMenu "Make uppercase" { ConvertTo-Case -Upper } "Alt+U"
    AddMenuItem $editMenu "Make lowercase" { ConvertTo-Case } "Alt+Shift+U"
    AddMenuItem $editMenu "Set writable" { Set-FileWritable } "Alt+W"
    AddMenuItem $editMenu "Sign File" { Write-Signature } "Alt+S"
}
Remove-variable 'editMenu'

# Add-ons menu items
AddMenuItem $rootMenu "Reset All Modules" { Reset-AllModules } "Alt+R"
AddMenuItem $rootMenu "Set ExecPol AllSigned" { Set-ExecutionPolicy allsigned } $null
AddMenuItem $rootMenu "Set ExecPol Unrestricted" { Set-ExecutionPolicy unrestricted } $null
AddMenuItem $rootMenu "Show Tab Filenames" { Get-IseFilenames } "Alt+F"
AddMenuItem $rootMenu "Open PS Profile" { Open-Profile } "Alt+O"
Remove-variable 'rootMenu'

# load the preferred theme
. Join-Path ([IO.Path]::GetDirectoryName($profile)) "\Themes\PSTheme_Selenitic.ps1" | Out-Null
