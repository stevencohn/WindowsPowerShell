<#
.SYNOPSIS
Report all installed applications registered on the local system.

.PARAMETER OutFile
The name of a CSV file to create. Default is to write to the console.

.PARAMETER Store
Include Microsoft Store applications.

.DESCRIPTION
When writing to the console, the number of column in the report is 
governed by the width of the console. When writing to CSV file, all
possible columns are reported.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[switch] $Store,
	[string] $OutFile
)

Begin
{
	$esc = [char]27

	function CollectKnownApplicationKeys
	{
		$root64 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
		$root32 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

		# enumerate HKLM\SOFTWARE\...
		# note this will be redirected to Wow6432Node if running from 32-bit on 64-bit Windows
		$appkeys = (Get-ChildItem $root64).Name | foreach { $_.replace('HKEY_LOCAL_MACHINE', 'HKLM:') }

		# enumerate HKLM\SOFTWARE\Wow6432Node\...
		$wowkeys = (Get-ChildItem $root32).Name | foreach { $_.replace('HKEY_LOCAL_MACHINE', 'HKLM:') }
		
		# join unique
		$appkeys += $wowkeys | where { $appkeys -notcontains (Join-Path $root64 (Split-Path $_ -leaf)) }

		$appkeys
	}

	function ExpandAppDetails
	{
		param([Parameter(ValueFromPipeline = $true)] [string] $key)
		Process
		{
			$item = Get-Item $key

			$name = $item.GetValue('DisplayName')
			if ([String]::IsNullOrWhiteSpace($name)) { return $null }

			#filter out updates and service packs
			if (($name -ccontains 'Update for') -or ($name -contains 'Service Pack')) { return $null }

			#filter out system components; these are usually windows updates
			$syscomp = $item.GetValue('SystemComponent')
			if ($syscomp) { if ($syscomp -eq 1) { return $null } }

			$installDate = $item.GetValue('InstallDate')
			if (-not [String]::IsNullOrWhiteSpace($installDate))
			{
				$installDate = $installDate.Substring(4, 2) + '/' + $installDate.Substring(6, 2) + '/' + $installDate.Substring(0, 4)
			}

			# If subkey's name is in Wow6432Node, then the application is 32-bit. Otherwise,
			# $is64Bit determines whether the application is 32-bit or 64-bit.
			$arch = '64-bit'
			if ($key -match 'Wow6432Node') { $arch = '32-bit' }

			New-Object PSObject -Property @{
				#ComputerName  = $computerName
				#Subkey        =  (split-path $key -parent) # useful when debugging
				AppID          = (Split-Path $key -leaf)
				DisplayName    = $name
				Publisher      = $item.GetValue('Publisher')
				DisplayVersion = $item.GetValue('DisplayVersion')
				Date           = $installDate
				Architecture   = $arch
				Store          = $false
			}
		}
	}

	function CollectKnownAppXKeys
	{
		$0 = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages'
		(Get-ChildItem $0 | where `
		{
			$_.GetValue('DisplayName') -notmatch 'ms-resource' -and
			$_.GetValue('SupportedUsers') -eq 0
		}).Name | foreach { $_.replace('HKEY_CURRENT_USER', 'HKCU:') }
	}

	function ExpandAppXDetails
	{
		param([Parameter(ValueFromPipeline = $true)] [string] $key)
		Process
		{
			$item = Get-Item $key

			$name = $item.GetValue('DisplayName')
			$users = $item.GetValue('SupportedUsers')
			if (($name -notmatch '^ms-resource:.*') -and $users -eq 0)
			{
				$packID = $item.GetValue('PackageID')
				$path = "$($env:ProgramFiles)\Windowsapps\$packID"
				if (Test-Path $path)
				{
					$xmlpath = Join-Path $path 'AppXManifest.xml'
					if (Test-Path $xmlpath)
					{
						[xml]$manifest = Get-Content $xmlpath
						$version = $manifest.Package.Identity.Version
						$publisher = $manifest.Package.Properties.PublisherDisplayName
						$arch = $manifest.Package.Identity.ProcessorArchitecture -match '64'
					}

					New-Object PSObject -Property @{
						AppID          = $packID
						DisplayName    = "$name (`$)"
						Publisher      = $publisher
						DisplayVersion = $version
						Date           = (Get-Item $path).CreationTime.ToShortDateString()
						Architecture   = @('64-bit','32-bit')[$arch]
						Store          = $true
					}
				}
			}
		}
	}

	function MakeExpression
	{
		param($store, $value)
		if ($store) { $color = '90' } else { $color = '37' }
		"$esc[$color`m$($value)$esc[0m"
	}
}
Process
{
	$confirm = [IO.Path]::Combine((Split-Path -parent $PSCommandPath), 'Test-Elevated.ps1')
	if (!(. $confirm (Split-Path -Leaf $PSCommandPath) -warn)) { return }

	$apps = CollectKnownApplicationKeys | ExpandAppDetails | where { $_ -ne $null }

	if ($Store)
	{
		$apps += (CollectKnownAppXKeys | ExpandAppXDetails)
	}

	$apps = $apps | Select-Object DisplayName, DisplayVersion, Date, Publisher, Architecture, AppID, Store | `
		Sort -Property DisplayName
	
	if ($OutFile -ne $null -and $OutFile.Length -gt 0)
	{
		$apps | Export-Csv -Path $OutFile
	}
	else
	{
       	# use 'Get-Colors -all' command to fine DOS [esc color numbers
		$apps | Format-Table `
			@{ Label = 'Name'; Expression = { MakeExpression $_.Store $_.DisplayName } },
			@{ Label = 'Version'; Expression = { MakeExpression $_.Store $_.DisplayVersion } },
			@{ Label = 'Date'; Expression = { MakeExpression $_.Store $_.Date } },
			@{ Label = 'Publisher'; Expression = { MakeExpression $_.Store $_.Publsher } },
			@{ Label = 'Architecture'; Expression = { MakeExpression $_.Store $_.Architecture } },
			@{ Label = 'AppID'; Expression = { MakeExpression $_.Store $_.AppID } } `
			-AutoSize
	}
}
