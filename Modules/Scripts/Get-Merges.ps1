<#
.SYNOPSIS
Reports all merges for the given git repo after a specified date

.PARAMETER Project
The name or path of a local git repo containing a .git\ subdirectory.
Defaults to the current directory.

.PARAMETER Branch
The name of the branch receiving merges to be reported

.PARAMETER After
A date of the form yyyy-mm-dd after which merges will be reported.
Default is the last 14 days

.PARAMETER Simple
A switch to display simple git log output
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
    [parameter(Position = 0)] [string] $Project,
    [parameter(Position = 1)] [string] $Branch,

    [string] $After,
    [switch] $Simple
    )

Begin
{
    function ReadBranch
    {
        $a = Get-Content .\.git\config | Select-String -Pattern '^\[branch "(.+)"\]$'
        if ($a.Matches.Success)
        {
            return $a.Matches.Groups[1].Value
        }

        return 'master'
    }

    function ReadRemote
    {
        $a = Get-Content .\.git\FETCH_HEAD | Select-String -Pattern '(https://.+?/)'
        if ($a.Matches.Success)
        {
			$url = $a.Matches.Groups[1].Value + 'jira/browse/'
			
			$request = [System.Net.WebRequest]::Create($url)
			$request.Timeout = 2000
			try {
				$response = $request.getResponse()
				if ($response.StatusCode -eq "200") 
				{
					return $url
				}
			} catch {}
        }

        Write-Verbose '*** could not determine remote URL'
        return $null
	}

    function Report
    {
        <#
        https://www.git-scm.com/docs/git-log

        %h  - abbrev commit hash (%H is full hash)
        %aN - author name
        C() - foreground color, %Creset resets foreground; Cred, Cgreen, Cblue
        %ar - author date relative
        %D  - ref names
        %s  - subject
        #>

		$remote = ReadRemote

		if ($Simple -or ($remote -eq $null))
        {
            git log --merges --first-parent $Branch --after $After `
                --pretty=format:"%h %<(12,trunc)%aN %C(white)%<(15)%ar%Creset %s %Cred%<(15)%D%Creset"
        }
        else
        {
            git log --merges --first-parent $Branch --after $After --pretty=format:"%h~%<(15,trunc)%aN~%ar~%s" | % `
            {
				Write-Verbose $_

                $parts = $_.Split('~')

                $a =$parts[3] | Select-String -Pattern "Merge pull request (#[0-9]+) .+ feature/([A-Z]+-[0-9]+)-(.+) to $Branch"
                if ($a.Matches.Success)
                {
                    $groups = $a.Matches.Groups

                    Write-Host "$($parts[1])  $($parts[2])  $remote$($a.Matches.Groups[2].Value)  PR $($groups[1].Value) $($groups[3].Value) "
                }
            }
        }
    }
}
Process
{
    if (!$Project) { $Project = '.' }
    if (!(Test-Path (Join-Path $project '.git')))
    {
        Write-Host '*** Enter the path to a local git repo or run from within a local repo' -ForegroundColor Yellow
        return
    }

    if ($Project -ne '.') { Push-Location $Project }

    if (!$Branch)
    {
        $Branch = ReadBranch
    }

    if (!$After)
    {
        $After = [DateTime]::Now.AddDays(-14).ToString('yyyy-MM-dd')
    }

    Report

    if ($Project -ne '.') { Pop-Location }
}
