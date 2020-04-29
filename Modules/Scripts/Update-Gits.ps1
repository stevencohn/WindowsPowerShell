<#
.SYNOPSIS
Scan all sub-folders looking for Git repos and fetch/pull each of them to
get latest code.

.PARAMETER Branch
Speciies the branch name, default is develop

.PARAMETER Project
Specifies the project (subfolder) to update. If not specified then it will
scan all subfolders and update every one that contains a .git folder. 

.PARAMETER Reset
Perform a hard reset to the tip of the specified Branch 
for each repo before fetch and pull. This is to discard all local changes.
#>

param (
    $Branch = 'develop',
    $Project,
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

        Write-Host $divider
        Write-Host "... updating $Project"

        Push-Location $Project

        if ($Reset)
        {
            git reset --hard origin/$Branch
        }

        git -c diff.mnemonicprefix=false -c core.quotepath=false fetch origin
        git -c diff.mnemonicprefix=false -c core.quotepath=false pull --no-commit origin $Branch

        Pop-Location
    }
}
Process
{
    if ($Project)
    {
        Update $Project
    }
    else
    {
        Get-ChildItem | ? { Test-Path (Join-Path $_.FullName '.git') } | `
            Select -ExpandProperty Name | ? { $_ -ne 'CDS' } | % { Update $_ }
    }
}
