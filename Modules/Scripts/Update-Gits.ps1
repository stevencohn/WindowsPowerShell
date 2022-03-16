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

        if ($Project -match '-skip')
        {
            Write-Host $divider
            Write-Host "... skipping $Project" -ForegroundColor DarkGray
            return
        }

        Push-Location $Project

        GetBranches

        $updated = (git log -1 --date=format:"%b %d, %Y" --format="%ad")
        Write-Verbose '$updated = (git log -1 --date=format:"%b %d, %Y" --format="%ad")'
        Write-Verbose "`$updated > $updated"

        if ($detached -and !$Branch -and !$Reset)
        {
            Write-Host $divider
            Write-Host "... detached HEAD at $active, last updated $updated" -ForegroundColor DarkGray
            return
        }

        $br = $Branch
        if (!$Branch)
        {
            if ($Reset -and $detached) { $br = $mainBr }
            else { $br = $active }
        }
        if ($br.StartsWith('origin/')) { $br = $br.Substring(7) }
        Write-Verbose "`$br > $br"

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
            if ($detached)
            {
                Write-Verbose "git checkout $br"
                git checkout $br
            }

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

    function GetBranches
    {
        $branches = (git branch)
        $script:active = $branches | ? { $_.startswith('*') } | % { $_.substring(2) }
        Write-Verbose '$active = git branch'
        Write-Verbose "`$active > $active"

        # get name of "main" branch from origin/HEAD
        $script:mainBr = (git branch -a | ? { $_ -match 'origin/HEAD -> (.*)' } | % { $Matches[1] })
        Write-Verbose '$mainBr = (git branch -a | ? { $_ -match ''origin/HEAD -> (.*)'' } | % { $Matches[1] })'
        Write-Verbose "`$mainBr > $mainBr"

        $script:detached = ($active -match '\(HEAD detached at ([a-f0-9]+)\)')
        if ($detached)
        {
            # $active will contain the commit hash
            $script:active = $matches[1]
            return
        }
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
        Get-ChildItem | `
            ? { Test-Path (Join-Path $_.FullName '.git') } | `
            Select -ExpandProperty Name | `
            % { Update $_ }
    }
}
