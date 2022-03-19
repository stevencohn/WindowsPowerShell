<#
.SYNOPSIS
Reports all commits to a named branch for the given git repo after a specified date.

.PARAMETER Project
The name or path of a local git repo containing a .git\ subdirectory. Defaults to the current
directory if there is a .git subdirectory or looks in all subdirectories for local git repos,
although it is not recursive.

.PARAMETER Branch
The name of the branch to report. Default is main.

.PARAMETER After
A date of the form yyyy-mm-dd after which commits will be reported. The Since parameter is a
synonym for this parameter. Default is the last $Last days

.PARAMETER Last
A number of days to subtract from the current date to calculate the After parameter.
Default is 14 days.

.PARAMETER Since
A date of the form yyyy-mm-dd after which commits will be reported.
Default is the last $Last days

.PARAMETER Raw
A switch to display raw git log output

.PARAMETER Graph
A switch to display raw graph git log output

.DESCRIPTION
Requires two environment variables:
$env:JIRA_URL of the form https://sub.domain.com without a trailing slash
$env:JIRA_TOKEN of the form username:token where token is the Jira API token
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[parameter(Position = 0)] [string] $Project,
	[parameter(Position = 1)] [string] $Branch,
	[string] $After,
	[string] $Since,
	[int] $Last = 14,
	[switch] $Raw,
	[switch] $Graph
)

Begin
{
	class IssueTicket
	{
		[string] $status
		[string] $type
	}
	
	$script:MergeCommit = 'merge-commit'
	$script:curlcmd = "$($env:windir)\System32\curl.exe"

	# cache IssueTickets; may be more than one commit per ticket, prevent repeat lookups
	$script:Tickets = @{}


	function Report
	{
		param (
			[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
			[string] $Project
		)

		Push-Location $Project

		if (!$Branch)
		{
			# get name of "main" branch from origin/HEAD
			$Branch = (git branch -a | ? { $_ -match 'origin/HEAD -> (.*)' } | % { $Matches[1] })
		}

		Write-Host
		Write-Host "$Project commits to $Branch since $Since" -ForegroundColor Blue
		Write-Host

		if ($raw -or $graph)
		{
			ReportRaw
		}
		else
		{
			SetupRemoteAccess
			ReportCommits
		}

		Pop-Location
	}


	function SetupRemoteAccess
	{
		if (!(Test-Path $curlcmd))
		{
			Write-Host "$0 does not exist" -ForegroundColor Red
			Write-Host 'Install curl from chocolatey.org with the command choco install curl' -ForegroundColor Yellow
			exit
		}

		if ($env:JIRA_URL -eq $null -or $env:JIRA_TOKEN -eq $null)
		{
			Write-Verbose 'could not determine remote access; set the JIRA_URL and JIRA_TOKEN env variables'
			$script:remote = $null
			return
		}

		# See https://developer.atlassian.com/cloud/jira/platform/basic-auth-for-rest-apis/

		$script:remote = "$($env:JIRA_URL)/rest/api/3/issue/"
		$script:token = $env:JIRA_TOKEN

		Write-Verbose "using remote $remote"
	}


	<#
	https://www.git-scm.com/docs/git-log

	%h  - abbrev commit hash (%H is full hash)
	%aN - author name
	C() - foreground color, %Creset resets foreground; Cred, Cgreen, Cblue
	%ad - author date, based on --date=format
	%ar - author date, relative
	%D  - ref names
	%s  - subject
	%GK - key used to sign commit

	--date-format options: (defaults to local time)
	https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/strftime-wcsftime-strftime-l-wcsftime-l
	#>

	function ReportRaw
	{
		if ($graph)
		{
			Write-Host "git log --all --graph  --abbrev-commit --date=relative " -NoNewline -ForegroundColor DarkGray
			Write-Host "--pretty=format:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'" -ForegroundColor DarkGray
			Write-Host

			git log --all --graph --abbrev-commit --date=relative `
				--pretty=format:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
		}
		else
		{
			Write-Host "git log --first-parent $Branch --after $Since " -NoNewline -ForegroundColor DarkGray
			Write-Host "--date=format-local:'%b %d %H:%M:%S' --pretty=format:""%h %<(15,trunc)%aN %ad %s %GK""" -ForegroundColor DarkGray
			Write-Host

			git log --first-parent $Branch --after $Since `
				--date=format-local:'%b %d %H:%M:%S' `--pretty=format:"%h %<(15,trunc)%aN %ad %s %GK"
		}
	}


	function ReportCommits
	{
		$lines = git log --first-parent $Branch --after $Since `
			--date=format-local:'%b %d %H:%M:%S' `--pretty=format:"%h~%<(15,trunc)%aN~%ad~%s~%GK"

		foreach ($line in $lines)
		{
			Write-Verbose $line
			$parts = $line.Split('~')

			# is it a merge commit... $groups[1]=PR, $groups[2]=ticket
			$a = $parts[3] | Select-String -Pattern "Merge pull request (#[0-9]+) from (?:[\w/]+/)?([A-Z]+-[0-9]+)[-_ ]?"
			if ($a.Matches.Success)
			{
				# ReportCommit(author, time, PR, ticket, $MergeCommit)
				$groups = $a.Matches.Groups
				ReportCommit $parts[1] $parts[2] $groups[1] $groups[2] $MergeCommit $parts[4]
				continue
			}

			# is it a commit... $groups[1]=ticket, $groups[2]=descr, $groups[3]=PR
			$a = $parts[3] | Select-String -Pattern "(?:fix|feat|[Ff]eature)?[/(]?([A-Z]+[- ][0-9]+)\)?[:-]?\s?(.+)?\s?\((#[0-9]+)\)$"
			if ($a.Matches.Success)
			{
				# ReportCommit(author, time, PR, ticket, description)
				$groups = $a.Matches.Groups
				ReportCommit $parts[1] $parts[2] $groups[3] $groups[1] $groups[2] $parts[4]
				continue
			}

			# is it dependabot... $groups[1]=desc, $groups[2]=PR
			$a = $parts[3] | Select-String -Pattern "build\(deps\): (.+)? \((#[0-9]+)\)$"
			if ($a.Matches.Success)
			{
				# ReportCommit(author, time, PR, '-', description)
				$groups = $a.Matches.Groups
				ReportCommit $parts[1] $parts[2] $groups[2] '-' $groups[1] $parts[4]
				continue
			}

			# untagged commit message but can we find a tagged branch name?
			$b = (git name-rev --name-only --exclude=tags/* $parts[0])
			if ($b -match '/([A-Za-z]+\-[0-9]+)')
			{
				$key = $matches[1]
				$a = $parts[3] | Select-String -Pattern "(.+)? \((#[0-9]+)\)$"
				if ($a.Matches.Success)
				{
					# extract and remove PR from descr
					$desc = $a.Matches.Groups[1]
					$pr = $a.Matches.Groups[2]
					ReportCommit $parts[1] $parts[2] $pr $key $desc $parts[4] -ForegroundColor Magenta
					continue
				}
			}

			# no idea what this is so just dump it out
			Write-Verbose "fallback... from $b"
			Write-Host $line.Replace('~', ' ') -ForegroundColor Magenta
		}
	}


	function ReportCommit
	{
		param(
			[string] $author,
			[string] $ago,
			[string] $pr,
			[string] $key,
			[string] $desc,
			[string] $sig
		)

		if ($ago.Length -lt 15) { $ago = $ago.PadRight(15) }

		if ($desc.Length -gt $sumax) { $desc = $desc.Substring(0, $sumax) + '..' }

		if (-not $key)
		{
			Write-Host "$author  $ago  PR $pr $desc"
			return
		}

		$key = $key.ToUpper().Replace(' ', '-')
		$pkey = $key.PadRight(12)

		if (-not $remote.StartsWith('http'))
		{
			Write-Host "$author  $ago  $pkey  PR $pr $desc" -ForegroundColor DarkMagenta
			return
		}

		$color = 'Gray'
		if ($desc -eq $MergeCommit) { $color = 'DarkGray' }
		if ($author.StartsWith('dependabot')) { $color = 'Magenta' }
		#if ($pr -eq '?') { $color = 'DarkMagenta' }

		$ticket = $tickets[$key]
		if ($ticket -eq $null)
		{
			#$cmd = "curl -s -u $($token) -X GET -H 'Content-Type: application/json' ""$remote$key"""
			#Write-Verbose $cmd

			$response = . $curlcmd -s -u $token -X GET -H 'Content-Type: application/json' "$remote$key" | ConvertFrom-Json
			#$response = curl -s "$remote$key" | ConvertFrom-Json
			if (-not ($response -and $response.fields))
			{
				Write-Host "$author  $ago  $pkey " -NoNewLine
				Write-Host 'unknown    ' -NoNewline -ForegroundColor DarkGray
				Write-Host "  PR $pr $desc" -ForegroundColor $color
				return
			}

			$ticket = [IssueTicket]::new();
			$ticket.status = $response.fields.status.name
			$ticket.type = $response.fields.issueType.name
			$script:tickets += @{ $key = $ticket }
		}

		if ($ticket.type -ne 'Story')
		{
			$desc = "($($ticket.type)) $desc"
			if ($ticket.type -eq 'Defect') { $color = 'DarkRed' } else { $color = 'DarkCyan' }
		}

		Write-Host "$author  $ago  $pkey " -NoNewline

		$storyStatus = $ticket.status.PadRight(11)
		switch ($ticket.status)
		{
			'Verified' { Write-Host $storyStatus -NoNewline -ForegroundColor Green }
			'Passed' { Write-Host $storyStatus -NoNewline -ForegroundColor Yellow }
			default { Write-Host $storyStatus -NoNewline -ForegroundColor Cyan }
		}

		if ($sig -eq $null -or $sig -eq '') { $sig = ' SIG-MISSING' } else { $sig = '' }

		$desc = $desc.Trim()
		$descSig = "$desc$sig"
		if ($descSig.Length -gt $sumax) { $descSig = $descSig.Substring(0, $sumax) + '..' }

		Write-Host "  PR $pr $desc$sig" -ForegroundColor $color
	}
}
Process
{
	if (!$Since) { $Since = $After }
	if (!$Since) { $Since = [DateTime]::Now.AddDays(-$Last).ToString('yyyy-MM-dd') }

	if (!$Project -and (Test-Path '.git')) { $Project = '.' }

	if (!$Project)
	{
		# report all Git repos under current directory
		Get-ChildItem | ? { Test-Path (Join-Path $_.FullName '.git') } | Select -ExpandProperty Name | % { Report $_ }
		return
	}

	if (!(Test-Path (Join-Path $Project '.git')))
	{
		Write-Host "*** $Project is not the path to a local repo" -ForegroundColor Yellow
		return
	}

	# max width of summary
	$script:sumax = $host.UI.RawUI.WindowSize.Width - 70

	Report $Project
}
