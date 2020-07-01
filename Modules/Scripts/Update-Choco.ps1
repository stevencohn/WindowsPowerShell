<#
.SYNOPSIS
Update all chocolatey packages, skipping those that we want to keep locked at a
specific version.
#>

# note that choco pin command doesn't seem to work as advertised!

choco upgrade all --except="'linqpad,linqpad5,nodejs,nodejs.install'"

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