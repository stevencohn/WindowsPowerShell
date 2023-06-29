$script:shell = 'PowerShell'
if ($PSVersionTable.PSVersion.Major -lt 6) { $script:shell = 'WindowsPowerShell' }

. $env:USERPROFILE\Documents\$shell\Microsoft.PowerShell_profile.ps1
