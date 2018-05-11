<#
.SYNOPSIS
Closes the current file - tab currently visible - in ISE.
This will first save the file if there are outstanding changes.
Typically bound to Alt-X
#>
function Close-CurrentFile ()
{
    foreach ($file in $psISE.CurrentPowerShellTab.Files)
    {
        if ($psISE.CurrentFile.DisplayName -eq $file.DisplayName)
        {
            if ($file.IsUntitled)
            {
                return
            }
            elseif ($file.IsUnsaved)
            {
                $file.Save()
            }

            # Write-Host $File.DisplayName
            $psISE.CurrentPowerShellTab.Files.Remove($file) | Out-Null
            break
        }
    }
}
