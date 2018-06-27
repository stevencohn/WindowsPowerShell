<#
.SYNOPSIS
Prune unused docker containers and dangling images.

.PARAMETER Volumes
Prune unused volumes.
#>

param ([switch] $Volumes)

if (!(Test-Elevated (Split-Path -Leaf $PSCommandPath) -warn)) { return }

Write-Host
$trash = $(docker ps -q -f "status=exited")
if ($trash -ne $null) {
	Write-Host ('Removing {0} stopped containers...' -f $trash.Count) -ForegroundColor DarkYellow
	docker container prune -f
}
else {
	Write-Host "No stopped containers" -ForegroundColor DarkYellow
}

Write-Host
$trash = $(docker images --filter "dangling=true" -q --no-trunc)
if ($trash -ne $null) {
	Write-Host ('Removing {0} dangling images...' -f $trash.Count) -ForegroundColor DarkYellow
	docker rmi $trash
}
else {
	Write-Host "No dangling images" -ForegroundColor DarkYellow
}

if ($Volumes)
{
	Write-Host
	$trash = $(docker volume ls --filter "dangling=true" -q)
	if ($trash -ne $null) {
		Write-Host ('Removing {0} dangling volumes...' -f $trash.Count) -ForegroundColor DarkYellow
		docker volume prune -f
	}
	else {
		Write-Host "No dangling volumes" -ForegroundColor DarkYellow
	}
}

Write-Host
