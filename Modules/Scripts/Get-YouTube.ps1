<#
.SYNOPSIS
Uses the yt-dlp choco package to download youtube videos as mp3 files.

.PARAMETER Url
The URL of the YouTube video to download.
#>

[CmdletBinding(SupportsShouldProcess = $true)]

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Url
)

Begin
{
    function Download
    {
        param([Parameter(Mandatory)][string]$url)

        # -x `                        # extract audio
        # --audio-format mp3 `        # format mp3
        # --audio-quality 0 `         # highest quality
        # --embed-thumbnail `         # embed thumbnail in the audio file
        # --add-metadata `            # add metadata to the audio file
        # -o "%(title)s.%(ext)s" `    # output filename pattern

        yt-dlp -x --audio-format mp3 --audio-quality 0 `
            --embed-thumbnail --add-metadata `
            -o "%(title)s.%(ext)s" $url
    }
}
Process
{
    Download $Url
}
