<#
.SYNOPSIS
Copies all music files referenced by the given playlist to the specified location.
For example, this can be used to copy music in an .m3u playlist file to a USB thumbdrive.

.PARAMETER Playlist
The path of the playlist file to export.

.PARAMETER Target
The folder path to which music is copied, can be a drive letter or a full or relative path.

.PARAMETER WhatIf
Use this to show which file references are valid and which are not without actually copying
anything.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[parameter(Position = 0, Mandatory = $true)]
    [string] $Playlist,

	[parameter(Position = 1, Mandatory = $true)]
    [string] $Target
)

Begin
{
	<#
	TODO: this doesn't seem to work. Given a filename "El Mañana.mp3", PowerShell will read
	it as " El MaA±ana.mp3" and this routine will convert it to "El MaA`̃±ana.mp3"
	#>
	function EscapeDiatritics
	{
		param ([string] $s)
		$normalized = $s.Normalize([System.Text.NormalizationForm]::FormD)
		$builder = New-Object -TypeName System.Text.StringBuilder
			
		$normalized.ToCharArray() | % `
		{
			if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -eq `
				[Globalization.UnicodeCategory]::NonSpacingMark)
			{
				[void]$builder.Append("``$_")
			}
			else
			{
				[void]$builder.Append($_)
			}
		}

		return $builder.ToString()
	}
}
Process
{
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
		# escape special chars like [ and ] to be `[ and `]
		$file = (EscapeDiatritics ([WildcardPattern]::Escape($_)))

		if (Test-Path $file)
		{
			$type = [System.IO.Path]::GetExtension($_)
			if ($type -ne '.mp3')
			{
				ConvertTo-Mp3 $file $Target #-Info
			}
			else
			{
				Write-Host "... copying $file"

				if (!$WhatIfPreference)
				{
					Copy-Item $file $Target -Force
				}
			}

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
}