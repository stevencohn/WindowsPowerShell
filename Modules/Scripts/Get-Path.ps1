<#
.SYNOPSIS
Display the PATH environment variable as a list of strings rathan than a single string
and displays the source of each value defined in the Registry: Machine, User, or Process

.PARAMETER search
An optional search string to find in each path.

.PARAMETER sort
Sorts the strings alphabetically, otherwise displays them in the order in which
they appear in the PATH environment variable

.DESCRIPTION
Reports whether each path references an existing directory, if it is duplicated in 
the PATH environment variable, if it is and empty entry. See the Repair-Path command
for a description of how it cleans up the PATH. Also reports the PATH length and
warns when it exceeds 80% capacity.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[string] $search,
	[switch] $sort
)

Begin
{
	function ExpandPath ($path)
	{
		# check env variables in path like '%USREPROFILE%'
		$match = [Regex]::Match($path, '\%(.+)\%')
		if ($match.Success)
		{
			$evar = [Environment]::GetEnvironmentVariable( `
					$match.Value.Substring(1, $match.Value.Length - 2))

			if ($evar -and ($evar.Length -gt 0))
			{
				return $path -replace $match.value, $evar
			}
		}

		return $path
	}
}
Process
{
	# In order to avoid substitution of environment variables in path strings
	# we must pull the Path property raw values directly from the Registry.
	# Other mechanisms such as [Env]::GetEnvVar... will expand variables.

	$0 = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
	$sysKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($0, $false <# readonly #>)
	$sysPaths = $sysKey.GetValue('Path', $null, 'DoNotExpandEnvironmentNames') -split ';'
	$sysExpos = $sysPaths | ? { $_ -match '\%.+\%' } | % { ExpandPath $_ }
	$sysKey.Dispose()

	$usrKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $false <# readonly #>)
	$usrPaths = $usrKey.GetValue('Path', $null, 'DoNotExpandEnvironmentNames') -split ';'
	$usrExpos = $usrPaths | ? { $_ -match '\%.+\%' } | % { ExpandPath $_ }
	$usrKey.Dispose()

	if ($VerbosePreference -eq 'Continue')
	{
		Write-Host 'Original System Paths' -ForegroundColor DarkYellow
		Write-Host ($sysPaths -join [Environment]::NewLine) -ForegroundColor DarkGray
		Write-Host 'Original User Paths' -ForegroundColor DarkYellow
		Write-Host ($usrPaths -join [Environment]::NewLine) -ForegroundColor DarkGray
		Write-Host
	}

	if ($sort) { $paths = $env:Path -split ';' | sort }
	else { $paths = $env:Path -split ';' }

	$duplicates = @()

	Write-Host
	$format = "{0,4}  {1}"

	foreach ($path in $paths)
	{
		$source = ''
		if (($sysExpos -contains $path) -or ($sysPaths -contains $path)) { $source += 'M' }
		if (($usrExpos -contains $path) -or ($usrPaths -contains $path)) { $source += 'U' }
		if ($source -eq '') { $source += 'P' }

		if ($path.Length -eq 0)
		{
			Write-Host '     -- EMPTY --' -ForegroundColor Yellow
		}
		elseif ($duplicates.Contains($path))
		{
			Write-Host("$format ** DUPLICATE" -f $source, $path) -ForegroundColor Yellow
		}
		else
		{
			if (!(Test-Path $path))
			{
				Write-Host("$format ** NOT FOUND" -f $source, $path) -ForegroundColor Red
			}
			elseif ($search -and $path.ToLower().Contains($search.ToLower()))
			{
				Write-Host($format -f $source, $path) -ForegroundColor Green
			}
			else
			{
				if ($source.Contains('P'))
				{
					Write-Host($format -f $source, $path) -ForegroundColor White
				}
				elseif ($source.Contains('U'))
				{
					if ($usrExpos -contains $path) { $source = "*$source" }
					Write-Host($format -f $source, $path) -ForegroundColor Gray
				}
				else
				{
					if ($sysExpos -contains $path) { $source = "*$source" }
					Write-Host($format -f $source, $path) -ForegroundColor DarkGray
				}
			}
		}

		$duplicates += $path
	}

	Write-Host
	Write-Host "PATH contains $($env:Path.Length) bytes" -NoNewline

	if (($env:Path).Length -gt ([Int16]::MaxValue * 0.80))
	{
		Write-Host ' .. exceeds 80% capacity; consider removing unused entries' -ForegroundColor Red
	}
	Write-Host
}
