<#
.SYNOPSIS
Creates a new elevated shortcut to a given target

.PARAMETER LinkPath
Path where the shortcut lnk file is to be created.
This should include the name of the link.lnk file

.PARAMETER TargetPath
Path of the executable to run from the shortcut

.PARAMETER Arguments
Arguments to pass to the executable
#>

param(
    [parameter(Mandatory=$True, HelpMessage='Path of shortcut lnk file to create')]
    [ValidateNotNullOrEmpty()]
    [string] $LinkPath,

    [parameter(Mandatory=$True, HelpMessage='Path of executable')]
    [ValidateNotNullOrEmpty()]
    [string] $TargetPath,

    [parameter(HelpMessage='Optional arguments to executable')]
    [string] $Arguments
)

if (Test-Path $TargetPath)
{
    $TargetPath = (Resolve-Path $TargetPath).Path
}
else
{
    Write-Warning "$TargetPath does not exist"
    return
}

$shortcut = (New-Object -comObject WScript.Shell).CreateShortcut($LinkPath)
$shortcut.TargetPath = $TargetPath

if ($Arguments)
{
    $shortcut.Arguments = $Arguments
}

$shortcut.Save()

# the magic...

$bytes = [IO.File]::ReadAllBytes($LinkPath)
$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
$bytes | Set-Content $LinkPath -Encoding Byte
