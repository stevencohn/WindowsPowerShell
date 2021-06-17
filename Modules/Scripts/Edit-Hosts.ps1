<#
.SYNOPSIS
Open the hosts file in Notepad.
#>

$file = "$env:windir\System32\drivers\etc\hosts"
if (!(Test-Path $file))
{
	Write-Host "... cannot find $file" -ForegroundColor Yellow
	return
}

if (!(Test-Elevated))
{
	Write-Host '... not currently elevated; you may not be able to save changes' -ForegroundColor Yellow
}

if (Get-Command 'notepad++')
{
	# npp handles files without extensions directly
	notepad++ $file
}
else
{
	notepad $file
}
