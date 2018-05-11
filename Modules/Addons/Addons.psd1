#
# Module manifest for profile Addons
#

@{
    ModuleVersion = '1.0'
    GUID = '654f29fc-7ce2-40d9-99b9-ef8bbf5ab079'
    Author = 'Steven M. Cohn'
    Copyright = '(c) 2013 Steven M. Cohn. All rights reserved.'
    PowerShellVersion = '3.0'
    NestedModules = @(
        'Close-CurrentFile.psm1',
        'ConvertTo-Case.psm1',
        'Copy-Colorized.psm1',
        'Get-IseFilenames.psm1',
        'Open-Profile.psm1',
        'Reset-AllModules.psm1',
        'Set-FileWritable.psm1',
        'Write-Signature.psm1'
        )
}
