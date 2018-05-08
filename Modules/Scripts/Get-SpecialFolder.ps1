<#
.SYNOPSIS
Return the translation of a SpecialFolder by name or show all SpecialFolders.

.DESCRIPTION
This command runs in two modes based on the switches, one and all. By default, it returns
the value of the named SpecialFolder by assuming the -one switch. If the -all switch is
specified then all SpecialFolders are shown and the folder parameter is used to highlight
matching results.

.PARAMETER folder
The name of the SpecialFolder enumeration to return or a substring of the folder names
to highlight

.PARAMETER all
Show all SpecialFolders.

.PARAMETER one
The default. Return the value of the named SpecialFolder.
#>

param (
	[Parameter(Position=0)] [string] $folder,
	[switch] $all)

if ($all)
{
	$format = '{0,-30} {1}'

	Write-Host ($format -f 'Name', 'Value')
	Write-Host ($format -f '----', '-----')

	$folders = @{}
	[Enum]::GetValues('System.Environment+SpecialFolder') | % `
	{
		if (!($folders.ContainsKey($_.ToString())))
		{
			$folders.Add($_.ToString(), [Environment]::GetFolderPath($_))
		}
	}

	$folders.GetEnumerator() | sort name | % `
	{
		$name = $_.Name.ToString()
		if ($name.Length -gt 30) { $name = $name.Substring(0,27) + '...' }

		$value = $_.Value.ToString()
		$max = $host.UI.RawUI.WindowSize.Width - 32
		if ($value.Length -gt $max) { $value = $value.Substring(0, $max - 3) + '...' }

		# when -all then $folder is a match string

		if ($folder -and ($_.Name -match $folder))
		{
			Write-Host ($format -f $name, $value) -ForegroundColor Green
		}
		elseif ([String]::IsNullOrEmpty($folder))
		{
			if ($_.Name -eq 'CommonApplicationData')
			{
				Write-Host ($format -f $name, $value) -ForegroundColor Blue				
			}
			elseif ($_.Name -match 'ApplicationData')
			{
				Write-Host ($format -f $name, $value) -ForegroundColor Magenta
			}
			elseif ($value -match "$env:USERNAME(?:\\\w+){0,1}$")
			{
				Write-Host ($format -f $name, $value) -ForegroundColor DarkGreen
			}
			else
			{
				Write-Host ($format -f $name, $value)
			}
		}
		else
		{
			Write-Host ($format -f $name, $value)
		}
	}
}
else
{
	if ([String]::IsNullOrEmpty($folder))
	{
		Write-Host "Specify a SpecialFolder name or -all" -ForegroundColor Yellow
		exit 1
	}
	if (-not [bool]($folder -as [Environment+SpecialFolder] -is [Environment+SpecialFolder]))
	{
		Write-Host "$folder is not a valid SpecialFolder name" -ForegroundColor Red
		exit 1
	}

	[Environment]::GetFolderPath($folder -as [Environment+SpecialFolder])
}
