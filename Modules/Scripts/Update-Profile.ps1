<#
.SYNOPSIS
Quick command line to pull latest source of the WindowsPowerShell repo from Github
#>

# strip off .\Modules\Scripts to get to .\WindowsPowerShell
$repo = $PSCommandPath | Split-Path -parent | Split-Path -parent | Split-Path -parent

if (!(Test-Path "$repo\.git" -PathType Container))
{
	Write-Host '... Profile location is not a cloned git repo.' -ForegroundColor Yellow
	Write-Host '... Clone from https://github.com/stevencohn/WindowsPowerShell.git' -ForegroundColor Yellow
	return
}

Push-Location $repo

git -c diff.mnemonicprefix=false -c core.quotepath=false fetch origin
git -c diff.mnemonicprefix=false -c core.quotepath=false pull --no-commit origin main

Pop-Location
