<#
.SYNOPSIS
Replace the path of all items in a playlist file to the current user's MyMusic path.

.PARAMETER Path
The path of the playlist files. Default is current directory

.PARAMETER Replace
The string to replace in each item path.

.PARAMETER Type
The file type of the playlists. Default is m3u

.DESCRIPTION
I use this because I maintain Dopamine playlists (.m3u files) on my primary device
and copy them to other devices which sometimes have different paths for MyMusic.
This quickly let's me update all .m3u files to the current machine's config.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[parameter(Position = 0, Mandatory = $true)]
    [string] $Replace,

    [string] $Path = $pwd,
    [string] $Type = 'm3u'
)

$slash = [IO.Path]::DirectorySeparatorChar
if (!($Replace.EndsWith($slash)))
{
    $Replace = $Replace + $slash
}

$music = [Environment]::GetFolderPath('MyMusic') + $slash
Write-Host "... Music is located here: $music"
Write-Host

Get-Item "*.$Type" | % `
{
    $fullName = $_.FullName
    Write-Host "... updating $fullName"

    (Get-Content $fullName | % { $_ -replace $Replace, $music }) | Set-Content $fullName
}
