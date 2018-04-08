
<#
.SYNOPSIS
Show containers and images in a single command.
#>
$confirm = [IO.Path]::Combine((Split-Path -parent $PSCommandPath), 'Confirm-Elevated.ps1')
if (!(. $confirm (Split-Path -Leaf $PSCommandPath) $true)) { return }

Write-Host
Write-Host 'Containers...' -ForegroundColor DarkYellow
docker ps -a
Write-Host
Write-Host 'Images...' -ForegroundColor DarkYellow
docker images
Write-Host
