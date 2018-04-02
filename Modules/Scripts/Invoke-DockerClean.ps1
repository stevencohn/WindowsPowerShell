<#
.SYNOPSIS
Prune unused docker containers and dangling images.
#>

$confirm = [IO.Path]::Combine((Split-Path -parent $PSCommandPath), 'Confirm-Elevated.ps1')
if (!(. $confirm 'Invoke-DockerClean' $true)) { return }

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

Write-Host
