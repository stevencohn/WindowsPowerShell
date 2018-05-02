<#
.SYNOPSIS
Clean up the PATH environment variable, removing duplicates, empty values, and
optionally paths that do not exist.

.PARAMETER Invalid
Remove invalid paths in addition to empty and duplicate paths.

.PARAMETER Yes
Respond to all prompts automatically with "Yes".

.PARAMETER WhatIf
Run the command and report changes but don't make any changes.

.DESCRIPTION
Also checks if there are user-specific paths in the Machine target and attempts to
move them to the User target.
#>

param (
	[switch] $Invalid,
	[switch] $Yes,
	[switch] $WhatIf)

Begin
{
	function CleanByTarget ($paths, $target)
	{
		$list = @()
		foreach ($path in $paths)
		{
			if ($path -eq '')
			{
				Write-Host ... removing empty path in $target
			}
			elseif ($list.Contains($path))
			{
				Write-Host ... removing duplicate path "$path" in $target
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
						Write-Host ... removing invalid path "$path" in $target
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

	function SkimUserPaths ($machpaths, $userpaths)
	{
		$profile = $env:USERPROFILE
		$mpaths = @()

		foreach ($path in $machpaths)
		{
			# if path starts with $env:USERPROFILE then it shouldn't be in Machine
			if ($path.StartsWith($profile))
			{
				if (!$userpaths.Contains($path))
				{
					$userpaths += $path
					Write-Host ... Moving to User path "$path"
				}
				else
				{
					Write-Host ... Removing Machine path "$path"
				}
			}
			# prefer User over Machine if in both
			elseif ($userpaths.Contains($path))
			{
				Write-Host ... Removing User path from Machine "$path"
			}
			else
			{
				$mpaths += $path
			}
		}

		return $mpaths, $userpaths
	}
}
Process
{
	$originalMachpaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine)
	$originalUserpaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User)

	# cleanup empty and invalid path entries
	$machpaths = CleanByTarget ($originalMachpaths -split ';') [EnvironmentVariableTarget]::Machine
	$userpaths = CleanByTarget ($originalUserpaths -split ';') [EnvironmentVariableTarget]::User

	# cleanup user-specific paths in Machine
	$machpaths, $userpaths = SkimUserPaths $machpaths $userpaths

	$machpaths = $machpaths -join ';'
	$userpaths = $userpaths -join ';'

	if (($machpaths -ne $originalMachpaths) -or ($userpaths -ne $originalUserpaths))
	{
		if ($WhatIf)
		{
			Write-Host 'WHATIF: pending changes ready to be applied' -ForegroundColor Yellow
		}
		else
		{
			$ans = Read-Host 'Apply changes? (Y/N) [Y]'
			if (($ans -eq 'y') -or ($ans -eq 'Y'))
			{
				[Environment]::SetEnvironmentVariable('PATH', $machpaths, [EnvironmentVariableTarget]::Machine)
				[Environment]::SetEnvironmentVariable('PATH', $userpaths, [EnvironmentVariableTarget]::User)
			}
		}
	}
	else
	{
		Write-Host No changes needed
	}
}
