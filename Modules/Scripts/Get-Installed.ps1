<#
.SYNOPSIS
Report all installed applications registered on the local system.

.PARAMETER OutFile
The name of a CSV file to create. Default is to write to the console.

.DESCRIPTION
When writing to the console, the number of column in the report is 
governed by the width of the console. When writing to CSV file, all
possible columns are reported.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param([string] $outFile)

Begin
{
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
			if ($syscomp) { if ($syscomp.uValue -eq 1) { return $null } }

			$app = New-Object PSObject
			#$app | add-member NoteProperty 'ComputerName' -value $computerName
			#$app | add-member NoteProperty 'Subkey' -value (split-path $key -parent) # useful when debugging
			$app | Add-Member NoteProperty 'AppID' -value (Split-Path $key -leaf)
			$app | Add-Member NoteProperty 'DisplayName' -value $name
			$app | Add-Member NoteProperty 'Publisher' -value $item.GetValue('Publisher')
			$app | Add-Member NoteProperty 'DisplayVersion' -value $item.GetValue('DisplayVersion')

			$installDate = $item.GetValue('InstallDate')
			if ($installDate) {
				if ($installDate -ne '') {
					$installDate = $installDate.Substring(4, 2) + '/' + $installDate.Substring(6, 2) + '/' + $installDate.Substring(0, 4)
				} 
			}
			$app | Add-Member NoteProperty 'Date' -value $installDate

			# If subkey's name is in Wow6432Node, then the application is 32-bit. Otherwise,
			# $is64Bit determines whether the application is 32-bit or 64-bit.
			if ($key -match 'Wow6432Node') {
				$app | Add-Member NoteProperty 'Architecture' -value '32-bit'
			}
			else {
				$app | Add-Member NoteProperty 'Architecture' -value '64-bit'
			}

			$app
		}
	}
}
Process
{
	$confirm = [IO.Path]::Combine((Split-Path -parent $PSCommandPath), 'Test-Elevated.ps1')
	if (!(. $confirm (Split-Path -Leaf $PSCommandPath) -warn)) { return }

	$apps = CollectKnownApplicationKeys | `
		ExpandAppDetails | where { $_ -ne $null } | `
		Select-Object DisplayName, DisplayVersion, Date, Publisher, Architecture, AppID | `
		Sort -Property DisplayName

	if ($outFile -ne $null -and $outFile.Length -gt 0)
	{
		$apps | Export-Csv -Path $outFile
	}
	else 
	{
		$apps | Format-Table -AutoSize
	}
}
