<#
.SYNOPSIS
Reports all merges for the given git repo after a specified date

.PARAMETER Project
The name or path of a local git repo containing a .git\ subdirectory.
Defaults to the current directory if there is a .git subdirectory or 
looks in all subdirectories for local git repos (not recursive)

.PARAMETER Branch
The name of the branch receiving merges to be reported

.PARAMETER After
A date of the form yyyy-mm-dd after which merges will be reported.
The Since parameter is a synonym for this parameter.
Default is the last $Last days

.PARAMETER Last
A number of days to subtract from the current date to calculate the
After parameter. Default is 14 days.

.PARAMETER Since
A date of the form yyyy-mm-dd after which merges will be reported.
Default is the last $Last days

.PARAMETER Raw
A switch to display raw git log output

.DESCRIPTION
Can override remote with $env:MERGE_REMOTE of the form https://sub.domain.com
without a trailing slash
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[parameter(Position = 0)] [string] $Project,
	[parameter(Position = 1)] [string] $Branch,

	[string] $After,
	[string] $Since,
	[int] $Last = 14,
	[switch] $Raw
)

Begin
{
	function ReadBranch
	{
		if (Test-Path .\.git\config)
		{
			$a = Get-Content .\.git\config | Select-String -Pattern '^\[branch "(.+)"\]$'
			if ($a.Matches.Success)
			{
				$0 = $a.Matches.Groups[1].Value
				Write-Verbose "found branch $0"
				return $0
			}
		}

		Write-Verbose 'defaulting to master branch'
		return 'master'
	}

	function ReadRemote
	{
		# temporary override with env variable, no trailing slash
		if ($env:MERGE_REMOTE)
		{
			$0 = "$($env:MERGE_REMOTE)/jira/rest/api/2/issue/"
			Write-Verbose "using remote $0"
			return $0
		}

		if (Test-Path .\.git\FETCH_HEAD)
		{
			$a = Get-Content .\.git\FETCH_HEAD | Select-String -Pattern '((?:https|ssh)://.+?/)'
			if ($a.Matches.Success)
			{
				$0 = $a.Matches.Groups[1].Value + 'jira/rest/api/2/issue/'
				Write-Verbose "found remote $0"
				return $0
			}
		}

		Write-Verbose 'could not determine remote URL'
		return $null
	}

	function ReportRaw
	{
		git log --merges --first-parent $Branch --after $Since `
			--pretty=format:"%h %<(12,trunc)%aN %C(white)%<(15)%ar%Creset %s %Cred%<(15)%D%Creset"
	}

	function ReportPretty
	{
		$lines = git log --merges --first-parent $Branch --after $Since --date=format-local:'%b %d %H:%M:%S' `--pretty=format:"%h~%<(15,trunc)%aN~%ad~%s"
		foreach ($line in $lines)
		{
			Write-Verbose $line

			$parts = $line.Split('~')

			$a = $parts[3] | Select-String `
				-Pattern "Merge pull request (#[0-9]+)(?: in [\w/]+)? from (?:(?:[\w/]+/)?([A-Z]+-[0-9]+)[-_ ]?(.+)?(?:to $Branch)?)"

			if ($a.Matches.Success)
			{
				$ago = $parts[2]
				if ($ago.Length -lt 12) { $ago = $ago.PadRight(12) }

				$groups = $a.Matches.Groups
				$ticket = ''
				if ($a.Matches.Groups[2].Value)
				{
					$key = $a.Matches.Groups[2].Value
					if ($remote.StartsWith('http'))
					{
						$response = curl -s "$($remote)$key" | ConvertFrom-Json
						$status = $response.fields.status.name.PadRight(8)

						$key = $key.PadRight(12)
						$ticket = "  $key $status"

						if ($response.fields.issueType.name -eq "Story")
						{
							Write-Host -NoNewLine $parts[1]
							Write-Host -NoNewLine '  '
							Write-Host -NoNewLine $ago
							Write-Host -NoNewLine '  '
							Write-Host -NoNewLine $key.PadRight(12)
							Write-Host -NoNewline ' '

							switch ($status)
							{
								"Verified" { Write-Host -NoNewline $status.PadRight(8) -ForegroundColor Green }
								"Passed" { Write-Host -NoNewline $status.PadRight(8) -ForegroundColor Yellow }
								default { Write-Host -NoNewline $status.PadRight(8) -ForegroundColor Cyan }
							}

							Write-Host "  PR $($groups[1].Value) $($groups[3].Value)"
						}
						else
						{
							Write-Host "$($parts[1])  $($ago)$ticket  PR $($groups[1].Value) $($groups[3].Value)" -ForegroundColor DarkGray
						}
					}
					else
					{
						$ticket = " $key"
						Write-Host "$($parts[1])  $($ago)$ticket  PR $($groups[1].Value) $($groups[3].Value)"
					}
				}
				else
				{
					Write-Host "$($parts[1])  $($ago)  PR $($groups[1].Value) $($groups[3].Value)"
				}
			}
			else
			{
				# should execute on first $line
				Write-Verbose "fallback: $line"
				ReportRaw
				break
			}
		}
	}

	function Report
	{
		param (
			[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
			[string] $Project
		)
		<#
		https://www.git-scm.com/docs/git-log

		%h  - abbrev commit hash (%H is full hash)
		%aN - author name
		C() - foreground color, %Creset resets foreground; Cred, Cgreen, Cblue
		%ad - author date, based on --date=format
		%D  - ref names
		%s  - subject

		--date-format options: (defaults to local time)
		https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/strftime-wcsftime-strftime-l-wcsftime-l
		#>

		Push-Location $Project

		if (!$Branch)
		{
			$Branch = ReadBranch
		}

		Write-Host
		Write-Host "Merges in $Project to $Branch since $Since" -ForegroundColor Blue
		Write-Host

		$remote = ReadRemote

		if ($Raw -or ($remote -eq $null))
		{
			ReportRaw
		}
		else
		{
			ReportPretty
		}

		Pop-Location
	}
}
Process
{
	if (!$Since) { $Since = $After }
	if (!$Since)
	{
		$Since = [DateTime]::Now.AddDays(-$Last).ToString('yyyy-MM-dd')
	}

	if (!$Project -and (Test-Path '.git')) { $Project = '.' }

	if (!$Project)
	{
		Get-ChildItem | ? { Test-Path (Join-Path $_.FullName '.git') } | Select -ExpandProperty Name | % { Report $_ }
		return
	}

	if (!(Test-Path (Join-Path $Project '.git')))
	{
		Write-Host "*** $Project is not the path to a local repo" -ForegroundColor Yellow
		return
	}

	Report $Project
}
