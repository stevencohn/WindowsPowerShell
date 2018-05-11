<#
.SYNOPSIS
Make the current file writable; disable the read-only flag
#>

function Set-FileWritable ()
{
    $file = $psISE.CurrentFile
    if (!$file.IsUntitled)
    {
        if ($file.FullPath -and (Test-Path $file.FullPath))
        {
            Set-ItemProperty $file.FullPath -name IsReadOnly -value $false
        }
    }
}
