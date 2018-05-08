
<#
.SYNOPSIS
Show containers and images in a single command.
#>

if (!(Confirm-Elevated (Split-Path -Leaf $PSCommandPath) -warn)) { return }

Write-Host
Write-Host 'docker ps -a' -ForegroundColor DarkYellow
docker ps -a
Write-Host
Write-Host 'docker images' -ForegroundColor DarkYellow
docker images
Write-Host
