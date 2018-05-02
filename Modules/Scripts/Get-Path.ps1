<#
.SYNOPSIS
Display the PATH environment variable as a list of strings rathan than a single string
and displays the source of each value defined in the Registry: Machine, User, or Process

.PARAMETER search
An optional search string to find in each path.

.PARAMETER sort
Sorts the strings alphabetically, otherwise displays them in the order in which
they appear in the PATH environment variable

.PARAMETER verbose
Dump the list of paths specific to the Machine and User registry entries.

.DESCRIPTION
Reports whether each path references an existing directory, if it is duplicated in 
the PATH environment variable, if it is and empty entry. See the Repair-Path command
for a description of how it cleans up the PATH.
#>

param (
	[string] $search,
	[switch] $sort, 
	[switch] $verbose)

$machpaths = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine) -split ';'
$userpaths = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User) -split ';'

$duplicates = @()

if ($sort)
{
	$paths = $env:Path -split ';' | sort
}
else
{
	$paths = $env:Path -split ';'
}

if ($verbose)
{
	Write-Host
	Write-Host 'Machine Paths' -ForegroundColor Green
	$machpaths | sort

	Write-Host
	Write-Host 'User Paths' -ForegroundColor Green
	$userpaths | sort

	Write-Host
	Write-Host 'Process Paths' -ForegroundColor Green
	$paths
}

Write-Host
$format = "{0,3}  {1}"

foreach ($path in $paths)
{
	$source = ''
	if ($machpaths.Contains($path)) { $source += 'M' }
	if ($userpaths.Contains($path)) { $source += 'U' }
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
		elseif ($source.Contains('P')) { Write-Host($format -f $source, $path) -ForegroundColor White }
		elseif ($source.Contains('U')) { Write-Host($format -f $source, $path) -ForegroundColor Gray }
		else { Write-Host($format -f $source, $path) -ForegroundColor DarkGray }
	}

	$duplicates += $path
}
