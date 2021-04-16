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

        Write-Verbose 'defaulting to master branch'
        return 'master'
    }

    function ReadRemote
    {
        $a = Get-Content .\.git\FETCH_HEAD | Select-String -Pattern '(https://.+?/)'
        if ($a.Matches.Success)
        {
			$url = $a.Matches.Groups[1].Value + 'jira/browse/'
		    return $url

            <#
			$request = [System.Net.WebRequest]::Create($url)
			$request.Timeout = 2000
			try {
				$response = $request.getResponse()
                $response
				if ($response.StatusCode -eq "200") 
				{
					return $url
				}
			} catch {
                $Error
            }
            #>
        }

        Write-Verbose 'could not determine remote URL'
        return $null
	}

    function Report
    {
        param (
            [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
            [string] $Project
        )
        <#
        https://www.git-scm.com/docs/git-log

        %h  - abbrev commit hash (%H is full hash)
        %aN - author name
        C() - foreground color, %Creset resets foreground; Cred, Cgreen, Cblue
        %ar - author date relative
        %D  - ref names
        %s  - subject
        #>

        Write-Host
        Write-Host "Merges in $Project since $After" -ForegroundColor Green
        Write-Host

        Push-Location $Project

        if (!$Branch)
        {
            $Branch = ReadBranch
        }

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

                $a =$parts[3] | Select-String -Pattern "Merge pull request (#[0-9]+)(?: .+ feature/([A-Z]+-[0-9]+)-(.+) to $Branch)?"
                if ($a.Matches.Success)
                {
                    $groups = $a.Matches.Groups
                    $uri = ''
                    if ($a.Matches.Groups[2].Value) { $uri = "  $remote$($a.Matches.Groups[2].Value)" }

                    Write-Host "$($parts[1])  $($parts[2])$uri  PR $($groups[1].Value) $($groups[3].Value) "
                }
            }
        }

        Pop-Location
    }
}
Process
{
    if (!$After)
    {
        $After = [DateTime]::Now.AddDays(-14).ToString('yyyy-MM-dd')
    }

    if (!$Project)
    {
        Get-ChildItem | ? { Test-Path (Join-Path $_.FullName '.git') } | Select -ExpandProperty Name | % { Report $_ }
    }
    else
    {
        if (!(Test-Path (Join-Path $Project '.git')))
        {
            Write-Host "*** $Project is not the path to a local repo" -ForegroundColor Yellow
            return
        }

        Report $Project
    }
}
