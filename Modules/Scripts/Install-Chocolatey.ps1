<#
.SYNOPSIS
Can be used on new machines to install Chocolately. If already installed then
checks if it is outdated and prompts to update.

.PARAMETER -Yes
Upgrade without prompting if an update is available.
#>

param ([switch] $Yes)

if (-not (Get-Command 'choco' -ErrorAction:Ignore))
{
	$installer = (New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')
	$signature = Get-AuthenticodeSignature -Content ([Text.Encoding]::Unicode.GetBytes($installer)) -SourcePathOrExtension 'install.ps1'

	if ($signature.Status -ne 'Valid')
 	{
		throw 'Got invalid signature on Chocolatey install.ps1'
	}

	if ($signature.SignerCertificate.Subject -ne 'CN="Chocolatey Software, Inc.", O="Chocolatey Software, Inc.", L=Topeka, S=Kansas, C=US')
 	{
		throw "Got untrusted Chocolatey signer $($signature.SignerCertificateSubject)"
	}
	Write-Host 'Install'
	Invoke-Expression $installer
}
else
{
	choco outdated -r

	# TODO: react...
	if ($Yes)
	{
		# blah...
	}
}
