<#
.SYNOPSIS
Clean up the PATH environment variable, removing duplicates, empty values, and
optionally paths that do not exist.

.PARAMETER Invalid
Remove invalid paths in addition to empty and duplicate paths.

.PARAMETER MachinePriority
Prefer machine target values over user target values when resolving duplicates;
default is to prefer user target values, removing duplicates from the machine target.

.PARAMETER Yes
Respond to all prompts automatically with "Yes".

.PARAMETER WhatIf
Run the command and report changes but don't make any changes.

.DESCRIPTION
Also checks if there are user-specific paths in the Machine target and attempts to
move them to the User target. Those that begin with the path to the user profile should
be defined in the User target. Those that begin with the SystemRoot path should be
defined in the Machine target. Those that are duplicated in the Machine and User target
are presumed to be intended for the User target and are removed from the Machine target,
unless -MachinePriority is specified.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[switch] $Invalid,
	[switch] $MachinePriority,
	[switch] $Yes)

Begin
{
	function RemoveInvalidPaths
	{
		param (
			[string[]] $paths,
			[EnvironmentVariableTarget] $target
		)

		$list = @()
		foreach ($path in $paths)
		{
			if ($path -eq '')
			{
				Write-Host "... removing empty $target path"
			}
			elseif ($list.Contains($path))
			{
				Write-Host "... removing duplicate $target path: $path"
			}
			else
			{
				if ($invalid)
				{
					if (Test-Path $path)
					{
						$list += $path
					}
					else
					{
						Write-Host "... removing invalid $target path: $path"
					}
				}
				else
				{
					$list += $path
				}
			}
		}

		return $list
	}

	function BalancePaths
	{
		param (
			[EnvironmentVariableTarget] $highname,
			[string[]] $highpaths,
			[string] $highprefix,
			[EnvironmentVariableTarget] $lowname,
			[string[]] $lowpaths,
			[string] $lowprefix
		)

		$lpaths = @()

		foreach ($path in $lowpaths)
		{
			# if path starts with specified highprefix then move it to highpaths
			if ($path.StartsWith($highprefix))
			{
				if (!$highpaths.Contains($path))
				{
					$highpaths += $path
					Write-Host ... moving to $highname`: "$path"
				}
				else
				{
					Write-Host ... removing $lowname`: "$path"
				}
			}
			# prefer High over Low if in both
			elseif (!$path.StartsWith($lowprefix) -and $highpaths.Contains($path))
			{
				Write-Host ... removing $highname path from $lowname`: "$path"
			}
			else
			{
				$lpaths += $path
			}
		}

		return $highpaths, $lpaths
	}

	function RebuildPath ($mpaths, $upaths)
	{
		$psroot = @((Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell'))
		$ppaths = @()
		
		$env:Path -split ';' | % `
		{
			if (!$mpaths.contains($_) -and !$upaths.contains($_) -and !$_.StartsWith($psroot))
			{
				$ppaths += $_
			}
		}

		$path = ($ppaths + $upaths + $mpaths + $psroot) -join ';'

		if ($WhatIfPreference)
		{
			$path = ($ppaths + $upaths + $mpaths + $psroot) -join [Environment]::NewLine
			Write-Host 'Newly updated env:PATH' -ForegroundColor DarkYellow
			Write-Host $path -ForegroundColor DarkGray
		}
		else
		{
			$env:Path = ($ppaths + $upaths + $mpaths + $psroot) -join ';'
		}
	}
}
Process
{
	# get Machine PATH and User PATH; Note that ($env:PATH - (Mach + User)) == Process PATH
	# Windows tends to append a semicolon to end of these in the Process Block which we can ignore
	$originalMachpaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine).TrimEnd(';')
	$originalUserpaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User).TrimEnd(';')

	if ($VerbosePreference -eq 'Continue')
	{
		Write-Host 'Original Machine Paths' -ForegroundColor DarkYellow
		Write-Host (($originalMachPaths -split ';' | sort) -join [Environment]::NewLine) -ForegroundColor DarkGray
		Write-Host 'Original User Target' -ForegroundColor DarkYellow
		Write-Host (($originalUserPaths -split ';' | sort) -join [Environment]::NewLine) -ForegroundColor DarkGray
		Write-Host
	}

	# cleanup empty and invalid path entries
	$machpaths = RemoveInvalidPaths ($originalMachpaths -split ';') 'Machine'
	$userpaths = RemoveInvalidPaths ($originalUserpaths -split ';') 'User'

	if ($MachinePriority)
	{
		# move machine-specific paths from User to Machine
		$machpaths, $userpaths = BalancePaths 'Machine' $machpaths $env:SystemRoot 'User' $userpaths $env:USERPROFILE
	}
	else
	{
		# cleanup user-specific paths in Machine
		$userpaths, $machpaths = BalancePaths 'User' $userpaths $env:USERPROFILE 'Machine' $machpaths $env:SystemRoot
	}

	if (($VerbosePreference -eq 'Continue') `
		-and (($machpaths -ne $originalMachpaths) -or ($userpaths -ne $originalUserpaths)))
	{
		Write-Host
		if ($machpaths -ne $originalMachpaths)
		{
			Write-Host 'Modified Machine Paths' -ForegroundColor DarkYellow
			Write-Host (($machpaths -split ';' | sort) -join [Environment]::NewLine) -ForegroundColor DarkGray
		}
		if ($userpaths -ne $originalUserpaths)
		{
			Write-Host 'Modified User Paths' -ForegroundColor DarkYellow
			Write-Host (($userPaths -split ';' | sort) -join [Environment]::NewLine) -ForegroundColor DarkGray
		}
		Write-Host
	}

	$machpaths = $machpaths -join ';'
	$userpaths = $userpaths -join ';'

	if (($machpaths -ne $originalMachpaths) -or ($userpaths -ne $originalUserpaths))
	{
		if ($WhatIfPreference)
		{
			RebuildPath $machpaths $userpaths

			Write-Host
			Write-Host 'WHATIF: run again without the -WhatIf parameter to apply changes' -ForegroundColor Yellow
		}
		else
		{
			$ans = Read-Host 'Apply changes? (Y/N) [Y]'
			if (($ans -eq 'y') -or ($ans -eq 'Y') -or ($ans -eq ''))
			{
				[Environment]::SetEnvironmentVariable('PATH', $machpaths, [EnvironmentVariableTarget]::Machine)
				[Environment]::SetEnvironmentVariable('PATH', $userpaths, [EnvironmentVariableTarget]::User)

				RebuildPath $machpaths $userpaths
			}
		}
	}
	else
	{
		Write-Host 'No changes needed'
	}
}
