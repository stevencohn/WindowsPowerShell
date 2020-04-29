<#
.SYNOPSIS
Scan all sub-folders looking for Git repos and fetch/pull each of them to
get latest code.

.PARAMETER Project
Specifies the project (subfolder) to update. If not specified then it will
scan all subfolders and update every one that contains a .git folder. 

.PARAMETER Reset
Perform a hard reset to the tip of the specified branch (master by default) 
for each repo before fetch and pull. This is to discard all local changes.
#>

param (
    $Project,
	$Reset
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

        if ($Reset -ne $null)
        {
            git reset --hard origin/$Reset
        }

        git -c diff.mnemonicprefix=false -c core.quotepath=false fetch origin
        git -c diff.mnemonicprefix=false -c core.quotepath=false pull --no-commit origin develop

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
