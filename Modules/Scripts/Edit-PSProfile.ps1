<#
.SYNOPSIS
Run VSCode with ~Documents\WindowsPowerShell as root folder
#>
code ([IO.Path]::GetDirectoryName($profile))

