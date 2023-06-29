# Copy all scripts in this project to %userprofile%\Documents\WindowsPowerShell

. $PSScriptRoot\common.ps1

$docPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) $shell

Copy-Item "$PSScriptRoot" "$docPath" -Recurse -Force -Exclude @("$this")
