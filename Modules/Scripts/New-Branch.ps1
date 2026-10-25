<#
.SYNOPSIS
Creates a new git branch following the "1234-word-word-word" naming convention.

.DESCRIPTION
Creates a local git branch named Name, where Name must start with a GitHub issue
number followed by hyphen-delimited words, e.g. "1234-fix-thing-here". Prints a
two-line commit message to the console: the full branch name with hyphens replaced
by spaces, and "Relates to #<issue>" -- copy/paste this into your first commit.
Warns and prompts for confirmation if the current branch is not 'main' or 'next' before
branching.

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
    function GetBranchMessage
    {
        param($Name, $Issue)

        return "$($Name -replace '-', ' ')`nRelates to #$Issue"
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

    if ($current -ne 'main' -and current -ne 'next')
    {
        Write-Host "Current branch is '$current', not 'main' or 'next'." -ForegroundColor Yellow
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

        Write-Host "Created branch '$Name' from '$current'" -ForegroundColor Cyan
        Write-Host ''

        $msg = GetBranchMessage $Name $issue
        Set-Clipboard $msg

        Write-Host 'This message is on the clipboard; paste it into your first commit:'
        write-host ''
        Write-Host $msg -ForegroundColor Green
    }
}
