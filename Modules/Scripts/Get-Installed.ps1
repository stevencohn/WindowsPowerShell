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

param([string] $outFile)

Begin
{
	$HKLM = [UInt32]'0x80000002'
	$UninstallKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
	$UninstallKeyWow = 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

	# Detect whether we are using pipeline input.
	$pipelineInput = (-not $PSBoundParameters.ContainsKey('ComputerName')) -and (-not $ComputerName)

	$comp = $env:COMPUTERNAME
	$reg = [WMIClass] "\\$comp\root\default:StdRegProv"


	# Returns $TRUE if the leaf items from both lists are equal; $FALSE otherwise.
	function Compare-LeafEquality ($list1, $list2)
	{
		# Create ArrayLists to hold the leaf items and build both lists.
		$leafList1 = New-Object System.Collections.ArrayList
		$leafList2 = new-Object System.Collections.ArrayList
		$list1 | % { [Void] $leafList1.Add((Split-Path $_ -leaf)) }
		$list2 | % { [Void] $leafList2.Add((Split-Path $_ -leaf)) }
		# If compare-object has no output, then the lists matched.
		(Compare-Object $leafList1 $leafList2 | Measure-Object).Count -eq 0
	}
        

	function Get-AllKnownApplicationKeys ()
	{
		$appkeys = New-Object System.Collections.ArrayList

		# Enumerate HKLM\SOFTWARE\... note that this request will be redirected to
		# Wow6432Node if running from 32-bit on 64-bit Windows
		$keys = $reg.EnumKey($HKLM, $UninstallKey)
		foreach ($key in $keys.sNames) {
			[Void] $appkeys.Add((Join-Path $UninstallKey $key))
		}

		# Enumerate HKLM\SOFTWARE\Wow6432Node\...
		$wowkeys = New-Object System.Collections.ArrayList
		$keys = $reg.EnumKey($HKLM, $UninstallKeyWow)
		if ($keys.ReturnValue -eq 0) {
			foreach ($key in $keys.sNames) {
				[Void] $wowkeys.Add((Join-Path $UninstallKeyWow $key))
			}
		}

		# Default to 32-bit. If there are any items in $wowkeys, then compare the leaf items
		# in both lists of subkeys. If the leaf items in both lists match, we're seeing the
		# Wow6432Node redirection in effect and we can ignore $wowkeys. Otherwise, we're 64-bit
		# and append $wowkeys to $appkeys to enumerate both.
		if ($wowkeys.Count -gt 0) {
			if (-not (Compare-Leafequality $appkeys $wowkeys)) {
				[Void] $appkeys.AddRange($wowkeys)
			}
		}

		$appkeys
	}

	function Get-InstalledInternal ()
	{
		New-Variable -Name is64Bit
		$appkeys = Get-AllKnownApplicationKeys

		# Enumerate the subkeys.
		foreach ($key in $appkeys) {
			$name = $reg.GetStringValue($HKLM, $key, 'DisplayName').sValue
			if ($name -eq $NULL) { continue }

			#filter out updates and service packs
			if (($name -ccontains 'Update for') -or ($name -contains 'Service Pack')) { continue; }

			#filter out system components; these are usually windows updates
			$syscomp = $reg.GetDWORDValue($HKLM, $key, 'SystemComponent')
			if ($syscomp) { if ($syscomp.uValue -eq 1) { continue; } }

			$app = New-Object PSObject
			#$app | add-member NoteProperty 'ComputerName' -value $computerName
			#$app | add-member NoteProperty 'Subkey' -value (split-path $key -parent) # useful when debugging
			$app | Add-Member NoteProperty 'AppID' -value (Split-Path $key -leaf)
			$app | Add-Member NoteProperty 'DisplayName' -value $name
			$app | Add-Member NoteProperty 'Publisher' -value $reg.GetStringValue($HKLM, $key, 'Publisher').sValue
			$app | Add-Member NoteProperty 'DisplayVersion' -value $reg.GetStringValue($HKLM, $key, 'DisplayVersion').sValue

			$installDate = $reg.GetStringValue($HKLM, $key, 'InstallDate').sValue
			if ($installDate) {
				if ($installDate -ne '') {
					$installDate = $installDate.Substring(4, 2) + '/' + $installDate.Substring(6, 2) + '/' + $installDate.Substring(0, 4) 
				} 
			}
			$app | Add-Member NoteProperty 'Date' -value $installDate

			# If subkey's name is in Wow6432Node, then the application is 32-bit. Otherwise,
			# $is64Bit determines whether the application is 32-bit or 64-bit.
			if ($key -like 'SOFTWARE\Wow6432Node\*') {
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

	if ($outFile -ne $null -and $outFile.Length -gt 0)
	{
		Get-InstalledInternal | `
			Select-Object DisplayName, DisplayVersion, Date, Publisher, Architecture, AppID | `
			Sort -Property DisplayName | `
			Export-Csv -Path $outFile
	}
	else 
	{
		Get-InstalledInternal | `
			Select-Object DisplayName, DisplayVersion, Date, Publisher, Architecture, AppID | `
			Sort -Property DisplayName | `
			Format-Table -AutoSize
	}
}
