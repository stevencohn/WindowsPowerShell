<#
.SYNOPSIS
Refresh the current session environment variables from the Registry by harvesting
from both the local machine and the current user hives.

.DESCRIPTION
Inspired by chocolatey.org's RefreshEnv.cmd script.
#>

Begin
{
    function Harvest
    {
        param($regpath)
        $path = ''
        $values = Get-ItemProperty $regpath
        $values | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | `
            where { $_ -notmatch '^PS' -and $_ -ne 'USERNAME' -and $_ -ne 'PROCESSOR_ARCHITECTURE'} | `
            foreach {
                if ($_ -eq 'PATH') {
                    $path = $values.$_
                } else {
                    Set-Item env:$_ "$($values.$_)"
                }
            }

        $path
    }
}
Process
{
    Write-Host '... refreshing environment variables from registry'

    $LMPath = Harvest 'HKLM:\\System\CurrentControlSet\Control\Session Manager\Environment'
    $CUPath = Harvest 'HKCU:\\Environment'

    Set-Item env:PATH "$LMPath;$CUPath"
}
