<#
.SYNOPSIS
Show containers and images in a single command with special color highlighting

.PARAMETER Containers
Same as -Ps. Show only containers unless -Images or -Volumes.

.PARAMETER Images
Show only images unless -Containers or -Volumes.

.PARAMETER Ps
Same as -Containers. Show only containers unless -Images or -Volumes.

.PARAMETER Volumes
Show volumes. Independent of other switches.
#>

param (
	[switch] $Ps,
	[switch] $Containers,
	[switch] $Images,
	[switch] $Volumes
)

Begin
{
	$script:e = [char]27
	$script:Gray = '90'
	$script:Green = '92'
	$script:Blue = '94'
	$script:Magenta = '95'
	$script:Cyan = '96'

	function ShowContainers
	{
		Write-Host
		Write-Host 'docker ps -a' -ForegroundColor DarkYellow

		# The --format argument doesn't like to accept double-quotes inside the format string
		# so the hack is to add tildes and then replace them later with double-quotes.
		# Also the command will return an array of strings so first join them into a single
		# string, replace the tildes, and finally build the full Json string...

		$ps = docker ps -a --no-trunc --format `
			'{ ~id~: ~{{.ID}}~, ~names~: ~{{.Names}}~, ~image~: ~{{.Image}}~, ~status~: ~{{.Status}}~, ~ports~: ~{{.Ports}}~ }'

		if ($ps)
		{
			$ps = '{{ "containers": [ {0} ] }}' -f ($ps -join ',').Replace('~', '"') | ConvertFrom-Json

			# we used --no-trunc to get full command port strings but we do want to truncate ID
			$ps.containers | % { $_.id = $_.id.Substring(0, 12) }

			$ps.containers | Format-Table id,
				@{
					Label = 'name'
					Expression = {
						if ($_.status -match '^Up') { $color = $Green } else { $color = $Gray }
						"$e[{0}m{1}$e[0m" -f $color,$_.names
					}
				},
				@{
					Label = 'image'
					Expression = {
						if ($_.image -match '^Waters') { $color = $Blue } else { $color = $Cyan }
						"$e[{0}m{1}$e[0m" -f $color,$_.image
					}
				},
				@{
					Label = 'status'
					Expression = {
						if ($_.status.StartsWith('Exited')) {
							$words = $_.status -split ' '
							@($words[0], $words[1], ($words[2] + $words[3][0]), 'ago') -join ' '
						} else {
							$_.status
						}
					}
				},
				ports
		}
		else
		{
			Write-Host "No containers`n" -ForegroundColor DarkGray
		}
	}

	function ShowImages
	{
		Write-Host 'docker images' -ForegroundColor DarkYellow

		$im = docker images --format `
			'{ ~id~: ~{{.ID}}~, ~repository~: ~{{.Repository}}~, ~tag~: ~{{.Tag}}~, ~created~: ~{{.CreatedSince}}~, ~size~: ~{{.Size}}~ }'

		if ($im)
		{
			$im = '{{ "images": [ {0} ] }}' -f ($im -join ',').Replace('~', '"') | ConvertFrom-Json

			$im.images | Format-Table id,
				@{
					Label='repository'
					Expression = {
						if ($_.repository -eq '<none>') { $color = $Gray }
						elseif ($_.repository -match 'azurecr|amazonaws') { $color = $Magenta }
						elseif ($_.repository -match '^Waters|^cds') { $color = $Blue }
						else { $color = $Cyan }
						"$e[{0}m{1}$e[0m " -f $color,$_.repository
					}
				},
				@{ Label='tag'; Expression={ $_.tag + ' ' } },
				@{ Label='created'; Expression={ $_.created + ' ' } },
				size
		}
		else
		{
			Write-Host "No images`n" -ForegroundColor DarkGray
		}
	}

	function ShowVolumes
	{
		Write-Host 'docker volume ls' -ForegroundColor DarkYellow

		$vo = docker volume ls --format '{ ~name~: ~{{.Name}}~, ~driver~: ~{{.Driver}}~, ~mountpoint~: ~{{.Mountpoint}}~ }'

		if ($vo)
		{
			$dangling = $(docker volume ls --filter "dangling=true" -q)

			$vo = '{{ "volumes": [ {0} ] }}' -f ($vo -join ',').Replace('~', '"').Replace('\','\\') | ConvertFrom-Json

			$vo.volumes | Format-Table driver,
				@{
					Label='mountpoint'
					Expression = {
						if ($dangling -contains $_.name) { $color = $Gray }
						else { $color = '0' }
						"$e[{0}m{1}$e[0m " -f $color,$_.mountpoint
					}
				}
		}
	}
}
Process
{
	if (!(Test-Elevated (Split-Path -Leaf $PSCommandPath) -warn)) { return }

	if (($Ps -or $Containers) -or !$Images)
	{
		ShowContainers
	}

	if ($Images -or !($Ps -or $Containers))
	{
		ShowImages
	}

	if ($Volumes) { ShowVolumes }
}