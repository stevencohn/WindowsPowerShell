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

		$script:remote = ReadRemote

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
		$lines = git log --merges --first-parent $Branch --after $Since `
			--date=format-local:'%b %d %H:%M:%S' `--pretty=format:"%h~%<(15,trunc)%aN~%ad~%s"

		foreach ($line in $lines)
		{
			Write-Verbose $line

			$parts = $line.Split('~')

			$a = $parts[3] | Select-String `
				-Pattern "Merge pull request (#[0-9]+)(?: in [\w/]+)? from (?:(?:[\w/]+/)?([A-Z]+-[0-9]+)[-_ ]?(.+)?(?:to $Branch)?)"

			if (-not $a.Matches.Success)
			{
				# should execute on first $line
				# repo is non-conformant so fallback entire report and exit quickly
				Write-Verbose "fallback: $line"
				ReportRaw
				break
			}

			$groups = $a.Matches.Groups

			ReportPrettyLine $parts[1] $parts[2] $groups[1] $groups[2] $groups[3]
		}
	}

	function ReportPrettyLine
	{
		param(
			[string] $author,
			[string] $ago,
			[string] $pr,
			[string] $key,
			[string] $desc
		)

		if ($ago.Length -lt 15) { $ago = $ago.PadRight(15) }

		if (-not $key)
		{
			Write-Host "$author  $ago  PR $pr $desc"
			return
		}

		$pkey = $key.PadRight(12)

		if (-not $remote.StartsWith('http'))
		{
			Write-Host "$author  $ago  $pkey  PR $pr $desc"
			return
		}

		$response = curl -s "$remote$key" | ConvertFrom-Json
		if (-not ($response -and $response.fields))
		{
			Write-Host "$author  $ago  $pkey " -NoNewLine
			Write-Host 'unknown    ' -NoNewline -ForegroundColor DarkGray
			Write-Host "  PR $pr $desc"
			return
		}

		$status = $response.fields.status.name
		$pstatus = $status.PadRight(11)

		if ($response.fields.issueType.name -eq "Story")
		{
			Write-Host "$author  $ago  $pkey " -NoNewline

			switch ($status)
			{
				"Verified" { Write-Host $pstatus -NoNewline -ForegroundColor Green }
				"Passed" { Write-Host $pstatus -NoNewline -ForegroundColor Yellow }
				default { Write-Host $pstatus -NoNewline -ForegroundColor Cyan }
			}

			Write-Host "  PR $pr $desc"
		}
		else
		{
			Write-Host "$author  $ago  $pkey $pstatus  PR $pr $desc (task)" -ForegroundColor DarkGray
		}
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
