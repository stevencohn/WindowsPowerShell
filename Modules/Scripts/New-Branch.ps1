<#
.SYNOPSIS
Creates a new git branch following the "1234-word-word-word" naming convention.

.DESCRIPTION
Creates a local git branch named Name, where Name must start with a GitHub issue
number followed by hyphen-delimited words, e.g. "1234-fix-thing-here". Sets the
branch description (git config branch.<name>.description) to two lines: the full
branch name with hyphens replaced by spaces, and "Relates to #<issue>". Warns and
prompts for confirmation if the current branch is not 'main' before branching.

.PARAMETER Name
The new branch name, of the form "1234-word-word-word" where 1234 is a GitHub
issue number.

.EXAMPLE
New-Branch 1234-fix-thing-here
#>

[CmdletBinding(SupportsShouldProcess = $true)]

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidatePattern('^\d+-[A-Za-z0-9]+(-[A-Za-z0-9]+)+$')]
    [string] $Name
)

Begin
{
    function SetBranchDescription
    {
        param($Name, $Issue)

        $description = "$($Name -replace '-', ' ')`nRelates to #$Issue"
        git config "branch.$Name.description" $description
        if ($LASTEXITCODE -ne 0) {
            Write-Host "*** failed to set description for branch '$Name'" -ForegroundColor Red
        }
    }
}
Process
{
    $issue = $null
    if ($Name -match '^(\d+)-') { $issue = $Matches[1] }

    $current = git rev-parse --abbrev-ref HEAD
    if ($LASTEXITCODE -ne 0) {
        Write-Host '*** cannot determine current branch; is this a Git repo?' -ForegroundColor Red
        return
    }

    if ($current -ne 'main')
    {
        Write-Host "Current branch is '$current', not 'main'." -ForegroundColor Yellow
        $go = Read-Host "Are you sure you want to branch from here? (y/n) [n]"
        if ($go -ne 'y')
        {
            Write-Host '*** aborted' -ForegroundColor Yellow
            return
        }
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Create git branch'))
    {
        git checkout -b $Name
        if ($LASTEXITCODE -ne 0) {
            Write-Host "*** failed to create branch '$Name'" -ForegroundColor Red
            return
        }

        SetBranchDescription $Name $issue

        Write-Host "Created branch '$Name' from '$current'" -ForegroundColor Cyan
    }
}
