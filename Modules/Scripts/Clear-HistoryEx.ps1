<#
Clears the PowerShell history file, retaining the specified number of most
recent commands.

.PARAMETER Keep
Specifies the number of commands to keep in the history file, where 0 would 
clear all history. The default is to keep the 300 most recent commands.
#>

[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[int] $Keep = 300
)

Begin
{
}
Process
{
    $script:savePath = (Get-PSReadlineOption).HistorySavePath
    $cache = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    Get-Content $savePath -Tail $Keep | Out-File $cache
    Copy-Item $cache $savePath -Force
    Remove-Item $cache -Force
}
