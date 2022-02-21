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
		$root = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
		$installer = "$root\Common7\IDE\vsixinstaller.exe"

		# TODO: update these versions every now and then...
		# The URIs are retrieved by visiting the page for each on marketplace.visualstudio.com
		# and copying the URL behind the big green Download button

		InstallVsix $installer 'EditorGuidelines' 'PaulHarrington/vsextensions/EditorGuidelines/2.2.8/vspackage'
		InstallVsix $installer 'MarkdownEditor' 'MadsKristensen/vsextensions/MarkdownEditor/1.12.253/vspackage'
		InstallVsix $installer 'SonarLint' 'SonarSource/vsextensions/SonarLintforVisualStudio2022/5.4.0.42421/vspackage'
		InstallVsix $installer 'SpecFlow' 'TechTalkSpecFlowTeam/vsextensions/SpecFlowForVisualStudio2022/2022.1.4.21914/vspackage'
		InstallVsix $installer 'VSColorOutput' 'MikeWard-AnnArbor/vsextensions/VSColorOutput/2.73/vspackage'

		Write-Host
		Write-Host '... Wait a couple of minutes for the VSIXInstaller processes to complete before starting VS' -Fore Yellow
	}


	function InstallVsix
	{
		param($installer, $name, $uri)
		Write-Host "... installing $name extension in the background" -ForegroundColor Yellow

		$url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$uri"
		$vsix = "$($env:TEMP)\$name`.vsix"

		# download package directly from VS Marketplace and install
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
		$progressPreference = 'silentlyContinue'
		Invoke-WebRequest $url -OutFile $vsix
		$progressPreference = 'Continue'

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

        InstallVisualStudio
    }
}
