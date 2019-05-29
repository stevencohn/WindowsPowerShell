<#
.SYNOPSIS
Clean up the PATH environment variable, removing duplicates, empty values, and
optionally paths that do not exist.

.PARAMETER Balance
Move user-specific paths from System target to User target and system-specific
paths from User target to System target. Duplicate paths that are in both will
remain in the User target.

.PARAMETER Yes
Respond to all prompts automatically with "Yes".

.PARAMETER WhatIf
Run the command and report changes but don't make any changes.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[switch] $Balance,
	[switch] $Yes)

Begin
{
	# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# Remove empty and unknown paths from the given collection
	# Also remove expanded duplicates of non-expanded variables
	function RemoveInvalidPaths
	{
		param (
			[string[]] $paths,
			[string[]] $expos,
			[string] $target
		)

		Write-Host "... cleaning $target" -ForegroundColor DarkYellow

		$list = @()
		foreach ($path in $paths)
		{
			if ($path -eq '')
			{
				Write-Host "... removing empty $target path"
			}
			elseif ($list -contains $path) # -contains is case-insensitive
			{
				Write-Host "... removing duplicate $target path: $path"
			}
			elseif ($expos -contains $path)
			{
				Write-Host "... removing expanded $target path: $path"
			}
			elseif (Test-Path (ExpandPath $path))
			{
				$list += $path
			}
			else
			{
				Write-Host "... removing invalid $target path: $path"
			}
		}

		$list
	}

	function ExpandPath ($path)
	{
		# check env variables in path like '%USREPROFILE%'
		$match = [Regex]::Match($path, '\%(.+)\%')
		if ($match.Success)
		{
			$evar = [Environment]::GetEnvironmentVariable( `
				$match.Value.Substring(1, $match.Value.Length -2))

			if ($evar -and ($evar.Length -gt 0))
			{
				return $path -replace $match.value, $evar
			}
		}

		return $path
	}


	# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# Consolidate duplicates into high collection from low collection
	# Move high prefix paths from low collection into high collection
	function BalancePaths
	{
		param (
			[string[]] $highpaths,
			[string[]] $highExpos,
			[string] $highprefix,
			[string] $highname,
			[string[]] $lowpaths,
			[string] $lowprefix,
			[string] $lowname
		)

		Write-Host "... balancing $lowname to $highname" -ForegroundColor DarkYellow

		$lpaths = @()

		foreach ($path in $lowpaths)
		{
			$expo = ExpandPath $path

			# if path starts with specified highprefix then move it to highpaths
			if ($expo.StartsWith($highprefix, 'CurrentCultureIgnoreCase'))
			{
				if (($highpaths -contains $expo) -or `
					($highExpos -contains $path) -or `
					($highpaths -contains $path))
				{
					Write-Host ... ignoring duplicate $lowname path`: "$path"
				}
				else
				{
					$highpaths += $path
					Write-Host ... moving from $lowname to $highname`: "$path"
				}
			}
			# prefer High over Low if in both
			elseif (!$path.StartsWith($lowprefix, 'CurrentCultureIgnoreCase') -and ($highpaths -contains $path))
			{
				Write-Host ... ignoring duplicate $lowname path`: "$path"
			}
			else
			{
				$lpaths += $path
			}
		}

		return $highpaths, $lpaths
	}

	# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# Rebuild the $env:PATH after the System and User paths have been cleaned
	# so the current session has the updated PATH settings
	function RebuildSessionPath ($sysPaths, $usrPaths)
	{
		$spaths = $sysPaths | % { ExpandPath $_ }
		$upaths = $usrPaths | % { ExpandPath $_ }

		$ppaths = @()
		
		# preserve per-session (process) entries
		$env:Path -split ';' | % `
		{
			if (!(($spaths -contains $_) -or ($upaths -contains $_) -or `
				$_.StartsWith($psroot, 'CurrentCultureIgnoreCase')))
			{
				$ppaths += ExpandPath $_
			}
		}

		$paths = $ppaths + $spaths + $upaths

		# ensure PowerShell scripts are in path
		$psroot = Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Modules\Scripts'
		if (!($paths -contains $psroot)) { $paths += $psroot }

		if ($WhatIfPreference)
		{
			Write-Host ([String]::New('-',80)) -ForegroundColor DarkYellow
			Write-Host 'Original $env:Path' -ForegroundColor DarkYellow
			Write-Host (($env:Path -split ';') -join [Environment]::NewLine) -ForegroundColor DarkGray
			Write-Host 'Updated env:PATH' -ForegroundColor DarkYellow
			Write-Host ($paths -join [Environment]::NewLine) -ForegroundColor DarkGray
		}
		else
		{
			$env:Path = $paths -join ';'
		}
	}
}
Process
{
	# In order to avoid substitution of environment variables in path strings
	# we must pull the Path property raw values directly from the Registry.
	# Other mechanisms such as [Env]::GetEnvVar... will expand variables.

	# open keys with write access ($true argument)
	$0 = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
	$sysKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($0, $true)
	$sysPath = $sysKey.GetValue('Path', $null, 'DoNotExpandEnvironmentNames')
	$sysPaths = $sysPath -split ';'
	$sysExpos = $sysPaths | ? { $_ -match '\%.+\%' } | % { (ExpandPath $_).ToLower() }

	$usrKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
	$usrPath = $usrKey.GetValue('Path', $null, 'DoNotExpandEnvironmentNames')
	$usrPaths = $usrPath -split ';'
	$usrExpos = $usrPaths | ? { $_ -match '\%.+\%' } | % { (ExpandPath $_).ToLower() }

	if ($VerbosePreference -eq 'Continue')
	{
		Write-Host 'Original System Paths' -ForegroundColor DarkYellow
		Write-Host ($sysPaths -join [Environment]::NewLine) -ForegroundColor DarkGray
		Write-Host 'Original User Paths' -ForegroundColor DarkYellow
		Write-Host ($usrPaths -join [Environment]::NewLine) -ForegroundColor DarkGray
		Write-Host
	}

	# cleanup empty and invalid path entries
	$sysPaths = RemoveInvalidPaths $sysPaths $sysExpos 'System'
	$usrPaths = RemoveInvalidPaths $usrPaths $usrExpos 'User'

	if ($Balance)
	{
		# move user paths from System to User
		$usrPaths, $sysPaths = BalancePaths $usrPaths $usrExpos $env:USERPROFILE 'User' $sysPaths $env:SystemRoot 'System'
		# move system paths from User to System
		$sysPaths, $usrPaths = BalancePaths $sysPaths $sysExpos $env:SystemRoot 'System' $usrPaths $env:USERPROFILE 'User'
	}

	$newSysPath = $sysPaths -join ';'
	$newUsrPath = $usrPaths -join ';'
	
	if ($VerbosePreference -eq 'Continue')
	{
		if ($newSysPath -ne $sysPath)
		{
			Write-Host 'New System Paths' -ForegroundColor DarkYellow
			Write-Host ($sysPaths -join [Environment]::NewLine) -ForegroundColor DarkGray
		}

		if ($newUsrPath -ne $usrPath)
		{
			Write-Host 'New User Paths' -ForegroundColor DarkYellow
			Write-Host ($usrPaths -join [Environment]::NewLine) -ForegroundColor DarkGray
		}
	}

	if (($newSysPath -ne $sysPath) -or ($newUsrPath -ne $usrPath))
	{
		if (-not $WhatIfPreference)
		{
			if ($Yes) { $ans = 'y' } else { $ans = Read-Host 'Apply changes? (Y/N) [Y]' }
			if (($ans -eq 'y') -or ($ans -eq 'Y') -or ($ans -eq ''))
			{
				if ($newSysPath -ne $sysPath) { $sysKey.SetValue('Path', $newSysPath, 'ExpandString') }
				if ($newUsrPath -ne $usrPath) { $usrKey.SetValue('Path', $newUsrPath, 'ExpandString') }

				RebuildSessionPath $sysPaths $usrPaths
			}
		}
		else
		{
			# if WhatIfPreference then this will just report
			RebuildSessionPath $sysPaths $usrPaths
		}
	}
	else
	{
		Write-Host
		Write-Host 'NO changes needed'
	}

	$sysKey.Dispose()
	$usrKey.Dispose()
}
