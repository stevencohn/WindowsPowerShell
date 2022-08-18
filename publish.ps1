# Copy all scripts in this project to %userprofile%\Documents\WindowsPowerShell

$docPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) "WindowsPowerShell"

Copy-Item "$PSScriptRoot" "$docPath" -Recurse -Force -Exclude @("$this")
