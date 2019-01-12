<#
.SYNOPSIS
List all external scripts and their parameter names. These are all of the
scripts implemented in your WindowsPowerShell profile Modules/Scripts folder.

.DESCRIPTION
Any aliases are listed along with each command.
#>

$sysparams = @(
	'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable',
	'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
	)

$aliases = @{}
Get-Alias | % { if ($aliases[$_.Definition] -eq $null) { $aliases.Add($_.Definition, $_.Name) } }

Get-Command -CommandType ExternalScript | % `
{
	$name = [IO.Path]::GetFileNameWithoutExtension($_.Name)
	Write-Host "$name " -NoNewline

	$parameters = $_.Parameters
	$parameters.Keys | ? { $sysparams -notcontains $_ } | % `
	{
		$p = $parameters[$_]
		$c = if ($p.ParameterType -like 'Switch') { 'DarkGray' } else { 'DarkCyan' }
		Write-Host "-$_ " -NoNewline -ForegroundColor $c
	}

	$alias = $aliases[$name]
	if ($alias) {
		Write-Host " ($alias)" -ForegroundColor DarkGreen -NoNewline
	}

	Write-Host
}

