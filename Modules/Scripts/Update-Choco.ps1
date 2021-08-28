<#
.SYNOPSIS
Update all chocolatey packages, skipping those that we want to keep locked at a
specific version.

.PARAMETER all
Same as -yes

.PARAMETER yes
Adds the -yes parameter, accepting all updates without prompting
#>

param([switch] $yes, [switch] $all)

# note that choco pin command doesn't seem to work as advertised!

$yesarg = ''
if ($yes -or $all) { $yesarg = '-y' }

#choco upgrade $yesarg all --except="'linqpad,linqpad5,linqpad5.install'"
choco upgrade $yesarg all

<#
param ()

Begin
{
	$script:excluding = 'linqpad', 'nodejs', '.install'


    function Update
    {
        param (
            [string] $Name
        )

        Write-Host
        Write-Host "... updating $name" -ForegroundColor Blue

        choco upgrade -y $name
    }
}
Process
{
    choco outdated -r | % `
    {
        $name = $_.split('|')[0]
        if ($null -eq ($excluding | ? { $name -match $_ }))
        {
            Update $name
        }
    }
}
#>