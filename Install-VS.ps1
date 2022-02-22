<#
.SYNOPSIS
Standalone script to install Visual Studio and its extensions.
This is bits and pieces of the Install-Programs.ps1 script

.PARAMETER Enterprise
Install Visual Studio Enterprise; default is to install Professional

.PARAMETER Extensions
Install general VSIX extenions
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[switch] $Enterprise,
    [switch] $Extensions
)

Begin
{
	function InstallCurl
	{
		if ((Get-Command curl).Source -ne '') { return }
		if ((choco list -l 'curl' | Select-string 'curl ').count -gt 0) { return }
	
		HighTitle 'Installing Curl'
		choco install -y curl
	}

	function DownloadBootstrap
	{
		# source=filename, target=folder
		param($source, $target)
		$zip = Join-Path $target $source
		curl -s "https://raw.githubusercontent.com/stevencohn/bootstraps/main/$source" -o $zip
		Expand-Archive $zip -DestinationPath $target -Force | Out-Null
		Remove-Item $zip -Force -Confirm:$false
	}

    function Highlight
	{
		param($text = '', $color = 'Yellow')
		$text | Write-Host -ForegroundColor Black -BackgroundColor $color
	}

	function HighTitle
	{
		param($title)
		Highlight '', "---- Installing $title ---------------------------"
	}


    function InstallVisualStudio
	{
		$0 = 'C:\Program Files\Microsoft Visual Studio\2022'
		$pro = Test-Path (Join-Path $0 'Professional\Common7\IDE\devenv.exe')
		$ent = Test-Path (Join-Path $0 'Enterprise\Common7\IDE\devenv.exe')
		if (!($pro -or $ent))
		{
			$sku = 'professional'
			if ($Enterprise) { $sku = 'enterprise' }

			HighTitle "Visual Studio 2022 ($sku)"
			Highlight '... This will take a few minutes'

			# download the installer
			$bits = "vs_$sku`_2022_17.0"
			DownloadBootstrap "$bits`.zip" $env:TEMP

			# run the installer
			& "$($env:TEMP)\$bits`.exe" --passive --config "$($env:TEMP)\vs_$sku`.vsconfig"

			Write-host '... Please wait for the installation to complete' -Fore Cyan
            Write-Host '... When complete, rerun this script using the -Extensions parameter' -Fore Cyan
		}
		else
		{
			Write-Host 'Visual Studio already installed' -ForegroundColor Green
		}
	}


	function InstallVSExtensions
	{
		HighTitle 'Visual Studio Extensions'

		# MS Marketplace no longer allows anonymous downloads so we've packaged our own
		# https://marketplace.visualstudio.com/items?itemName=PaulHarrington.EditorGuidelines
		# https://marketplace.visualstudio.com/items?itemName=SonarSource.SonarLintforVisualStudio2022
		# https://marketplace.visualstudio.com/items?itemName=SonarSource.SonarLintforVisualStudio2022
		# https://marketplace.visualstudio.com/items?itemName=TechTalkSpecFlowTeam.SpecFlowForVisualStudio2022
		# https://marketplace.visualstudio.com/items?itemName=MikeWard-AnnArbor.VSColorOutput64

		DownloadBootstrap "vs_extensions_2022.zip" $env:TEMP

		$root = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
		$installer = "$root\Common7\IDE\vsixinstaller.exe"

		InstallVsix $installer 'EditorGuidelines'
		InstallVsix $installer 'MarkdownEditor'
		InstallVsix $installer 'SonarLint'
		InstallVsix $installer 'SpecFlow'
		InstallVsix $installer 'VSColorOutput'

		Write-Host
		Write-Host '... waiting for all VSIXInstaller processes to complete; this will take a couple of minutes' -Fore Yellow
		Write-Host '... ' -NoNewline

		Wait-Process -Name 'VSIXInstaller'

		Write-host '... installation complete'
	}


	function InstallVsix
	{
		param($installer, $name)
		Write-Host "... installing $name extension in the background" -ForegroundColor Yellow
		$vsix = "$($env:TEMP)\$name`.vsix"
		& $installer /quiet /norepair $vsix
	}
}
Process
{
    if ($Extensions)
    {
        InstallVSExtensions
    }
    else
    {
        Write-Host '*** This installer will require a system reboot'
        Write-Host '*** It is highly recommend that you close Visual Studio, VSCode, and Office apps'
        Read-Host '*** Press Enter to continue'

        Write-Host '... clearing the %TEMP% folder'
		Remove-Item -Path "$env:TEMP\*" -Force -Recurse -ErrorAction:SilentlyContinue

		InstallCurl
        InstallVisualStudio
    }
}
