<#
.SYNOPSIS
Display a table showing the full path file names of each
file tab in the ISE editor
#>
function Get-IseFilenames ()
{
    [System.Windows.Forms.SendKeys]::SendWait("^1")
    $psISE.CurrentPowerShellTab.Files | % { @{$_.DisplayName = $_.FullPath} } 
}
