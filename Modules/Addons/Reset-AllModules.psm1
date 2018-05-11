<#
.SYNOPSIS
Reload/refresh all loaded modules in ISE environment
Useful for resetting context between debugging sessions
#>

function Reset-AllModules ()
{
    $mods = Get-Module -All | ? { $_.ModuleType -eq 'Script' -and $_.Name -ne 'ISE' -and !$_.Name.StartsWith('Microsoft.') }
    $mods | Import-Module -Force
    Write-Host ... Reloaded $mods.Count modules -ForegroundColor Gray
}
