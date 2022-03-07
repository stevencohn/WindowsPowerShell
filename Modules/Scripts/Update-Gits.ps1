<#
.SYNOPSIS
Scan all sub-folders looking for Git repos and fetch/pull each of them to
get latest code.

.PARAMETER Branch
Speciies the branch name, default is read from the .git\config file

.PARAMETER Merge
Merges main into the feature branch if the current branch is not main

.PARAMETER Project
Specifies the project (subfolder) to update. If not specified then it will
scan all subfolders and update every one that contains a .git folder. 

.PARAMETER Reset
Perform a hard reset to the tip of the specified Branch 
for each repo before fetch and pull. This is to discard all local changes.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[Parameter(Position=0)] [string] $Project,
	[Parameter(Position=1)] [string] $Branch,
    [switch] $Merge,
	[switch] $Reset
)

Begin
{
	$script:divider = New-Object String('-', 80)


    function Update
    {
        param (
            [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
            [string] $Project
        )

        Push-Location $Project

        $br = $branch
        if (!$Branch)
        {
            $br = (git symbolic-ref --short HEAD)
            Write-Verbose '$br = (git symbolic-ref --short HEAD)'
            Write-Verbose "`$br > $br"
        }

        $updated = (git log -1 --date=format:"%b %d, %Y" --format="%ad")
        Write-Verbose '$updated = (git log -1 --date=format:"%b %d, %Y" --format="%ad")'
        Write-Verbose "`$updated > $updated"

        # get name of "main" branch from origin/HEAD
        $mainBr = (git branch -a | ? { $_ -match 'origin/HEAD -> (.*)' } | % { $Matches[1] })
        Write-Verbose '$mainBr = (git branch -a | ? { $_ -match ''origin/HEAD -> (.*)'' } | % { $Matches[1] })'
        Write-Verbose "`$mainBr > $mainBr"

        Write-Host $divider
        $expected = $mainBr
        if ($expected.StartsWith('origin/')) { $expected = $mainBr.Substring(7) }
        if ($br -eq $expected) {
            Write-Host "... updating $Project from $br, last updated $updated" -ForegroundColor Blue
        } else {
            Write-Host "... updating $Project from " -ForegroundColor Blue -NoNewline
            Write-Host $br -ForegroundColor DarkYellow -NoNewline
            Write-Host ", last updated $updated" -ForegroundColor Blue
        }

        if ($Reset)
        {
            # revert uncommitted changes that have been added to the index
            Write-Verbose "git reset --hard origin/$br"
            git reset --hard origin/$br
            # revert uncommitted, unindexed changes (f=force, d=recurse, x=uncontrolled)
            Write-Verbose 'git clean -dxf'
            git clean -dxf
        }

        ($br -match '(?:origin/)?(.*)') | out-null ; $shortBr = $matches[1]
        ($mainBr -match '(?:origin/)?(.*)') | out-null ; $shortMain = $matches[1]

        if ($Merge -and ($shortBr -ne $shortMain))
        {
            Write-Host "... merging $mainBr into $br" -ForegroundColor DarkCyan
            Write-Verbose "git fetch origin $shortMain"
            git fetch origin $shortMain
            Write-Verbose "git merge $mainBr"
            git merge $mainBr
        }

        Write-Verbose 'git fetch'
        git fetch #origin
        Write-Verbose 'git pull'
        git pull #origin $br

        if ($LASTEXITCODE -ne 0)
        {
            Write-Host
            Write-Host "*** failed git pull origin $br" -ForegroundColor Red
            Write-Host
        }

        Pop-Location
    }
}
Process
{
    if ($Project)
    {
        $Host.PrivateData.VerboseForegroundColor = 'DarkGray'
        Update $Project
        $Host.PrivateData.VerboseForegroundColor = 'Yellow'
    }
    else
    {
        Get-ChildItem | ? { Test-Path (Join-Path $_.FullName '.git') } | Select -ExpandProperty Name | % { Update $_ }
    }
}
