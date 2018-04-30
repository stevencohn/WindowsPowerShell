<#
.synopsis
Display the PATH environment variable as a list of strings rathan than a single string
and displays the source of each value defined in the Registry: Machine, User, or Process

.parameter search
An optional search string to find in each path.

.parameter sort
Sorts the strings alphabetically, otherwise displays them in the order in which
they appear in the PATH environment variable

.parameter verbose
Dump the list of paths specific to the Machine and User registry entries.
#>

param (
	[string] $search,
	[switch] $sort, 
	[switch] $verbose)

$machpaths = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine) -split ';'
$userpaths = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User) -split ';'

if ($verbose)
{
	Write-Host
	Write-Host 'Machine Paths' -ForegroundColor Green
	$machpaths | sort

	Write-Host
	Write-Host 'User Paths' -ForegroundColor Green
	$userpaths | sort
}

$duplicates = @()

if ($sort)
{
	$paths = $env:Path -split ';' | sort
}
else
{
	$paths = $env:Path -split ';'
}

Write-Host

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
		Write-Host("{0,3}  {1} ** DUPLICATE" -f $source, $path) -ForegroundColor Yellow
	}
	else
	{
		if ($search -and $path.ToLower().Contains($search.ToLower()))
		{
			Write-Host("{0,3}  {1}" -f $source, $path) -ForegroundColor Green
		}
		elseif ($source.Contains('P')) { Write-Host("{0,3}  {1}" -f $source, $path) -ForegroundColor White }
		elseif ($source.Contains('U')) { Write-Host("{0,3}  {1}" -f $source, $path) -ForegroundColor Gray }
		else { Write-Host("{0,3}  {1}" -f $source, $path) -ForegroundColor DarkGray }
	}

	$duplicates += $path
}
