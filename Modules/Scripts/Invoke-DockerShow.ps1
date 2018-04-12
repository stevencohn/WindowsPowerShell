
<#
.SYNOPSIS
Show containers and images in a single command.
#>

if (!(Confirm-Elevated (Split-Path -Leaf $PSCommandPath) $true)) { return }

Write-Host
Write-Host 'Containers...' -ForegroundColor DarkYellow
docker ps -a
Write-Host
Write-Host 'Images...' -ForegroundColor DarkYellow
docker images
Write-Host
