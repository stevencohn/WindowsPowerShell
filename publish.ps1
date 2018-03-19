# Copy all scripts in this project to %userprofile%\Documents\WindowsPowerShell

$this = Split-Path -Leaf $PSCommandPath
$spath = Split-Path -parent $PSCommandPath
$tpath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) "WindowsPowerShell"

Copy-Item "$spath" "$tpath" -Recurse -Force -Exclude @("$this")
