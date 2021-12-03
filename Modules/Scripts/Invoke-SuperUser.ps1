<#
.SYNOPSIS
Open a new command prompt in elevated mode - alias 'su'
#>
Start-Process -Verb RunAs cmd.exe '/c start wt.exe -p "Windows PowerShell"'
