<#
.SYNOPSIS
Copies all music files referenced by the given playlist to the specified location.
For example, this can be used to copy music in an .m3u playlist file to a USB thumbdrive.

.PARAMETER Playlist
The path of the playlist file to export.

.PARAMETER Target
The folder path to which music is copied, can be a drive letter or a full or relative path.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[parameter(Position = 0, Mandatory = $true)]
    [string] $Playlist,

	[parameter(Position = 1, Mandatory = $true)]
    [string] $Target
)

Write-Host

if (!(Test-Path $Playlist))
{
	Write-Host '... playlist not found' -ForegroundColor Yellow
	return
}

if (!(Test-Path $Target))
{
	Write-Host '... target location not found' -ForegroundColor Yellow
	return
}

$slash = [IO.Path]::DirectorySeparatorChar
if (!($Target.EndsWith($slash)))
{
    $Target = $Target + $slash
}

$count = 0
$missed = 0
Get-Content $Playlist | % `
{
	$file = $_
	if (Test-Path $file)
	{
		Write-Host "... copying $file"
		Copy-Item $file $Target -Force
		$count = $count + 1
	}
	else
	{
		Write-Host "... $file not found" -ForegroundColor DarkYellow
		$missed = $missed + 1
	}
}

Write-Host
Write-Host "... copied $count files, missed $missed files" -ForegroundColor DarkGray
