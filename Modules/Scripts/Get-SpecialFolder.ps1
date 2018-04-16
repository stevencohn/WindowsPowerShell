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
	# normally the folder argument could be declared as a [Environment+SpecialFolder] type
	# but we need it to act as both a SpecialFolder name and a highlight substring. 
	[Parameter(Mandatory=$True, Position=0, ParameterSetName='One')]
	[Parameter(Mandatory=$False, Position=0, ParameterSetName='All')]
	[ValidateScript({
		if ($all -or [bool]($_ -as [Environment+SpecialFolder] -is [Environment+SpecialFolder])) {
			$true
		}
		else {
			Throw 'Invalid SpecialFolder name'
		}
	})]
	[string] $folder,

	[Parameter(Mandatory=$True, ParameterSetName='One')]
	[switch] $one = $true,

	[Parameter(Mandatory=$False, ParameterSetName='All')]
	[switch] $all
	)

if ($all)
{
	Write-Host ("{0,-30} {1}" -f 'Name', 'Value')
	Write-Host ("{0,-30} {1}" -f '----', '-----')

	$folders = @{}
	[Enum]::GetValues('System.Environment+SpecialFolder') | % `
	{
		if (!($folders.ContainsKey($_.ToString())))
		{
			$folders.Add($_.ToString(), [Environment]::GetFolderPath($_))
		}
	}

	$pairs = $folders.GetEnumerator() | sort name | % `
	{
		$name = $_.Name.ToString()
		if ($name.Length -gt 30) { $name = $name.Substring(0,27) + '...' }

		$value = $_.Value.ToString()
		$max = $host.UI.RawUI.WindowSize.Width - 32
		if ($value.Length -gt $max) { $value = $value.Substring(0, $max - 3) + '...' }

		if ($folder -and ($_.Name -match $folder))
		{
			Write-Host ("{0,-30} {1}" -f $name, $value) -ForegroundColor Green
		}
		elseif ([String]::IsNullOrEmpty($folder))
		{
			if ($_.Name -eq 'CommonApplicationData')
			{
				Write-Host ("{0,-30} {1}" -f $name, $value) -ForegroundColor Blue				
			}
			elseif ($_.Name -match 'ApplicationData')
			{
				Write-Host ("{0,-30} {1}" -f $name, $value) -ForegroundColor Magenta
			}
			elseif ($value -match "$env:USERNAME(?:\\\w+){0,1}$")
			{
				Write-Host ("{0,-30} {1}" -f $name, $value) -ForegroundColor DarkGreen
			}
			else
			{
				Write-Host ("{0,-30} {1}" -f $name, $value)
			}
		}
		else
		{
			Write-Host ("{0,-30} {1}" -f $name, $value)
		}
	}
}
else
{
	[Environment]::GetFolderPath($folder -as [Environment+SpecialFolder])
}
