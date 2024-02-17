<#
.SYNOPSIS
Standalone script to install Visual Studio or VSCode and their extensions.

All parameters are mutually exlusive!

.PARAMETER Code
Install VSCode; default is to install Visual Studio Professional

.PARAMETER Community
Install Visual Studio Community; default is to install Professional

.PARAMETER Enterprise
Install Visual Studio Enterprise; default is to install Professional

.PARAMETER Extensions
Install general VSIX extenions

.PARAMETER Professional
Install Visual Studio Professional
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName='pr')]

param (
	[Parameter(ParameterSetName='cd', Mandatory=$false)] [switch] $Code,
	[Parameter(ParameterSetName='pr', Mandatory=$false)] [switch] $Professional,
	[Parameter(ParameterSetName='en', Mandatory=$false)] [switch] $Enterprise,
	[Parameter(ParameterSetName='cm', Mandatory=$false)] [switch] $Community,
	[Parameter(ParameterSetName='ex', Mandatory=$false)] [switch] $Extensions
)

Begin
{
	. $PSScriptRoot\common.ps1

	$Year = '2022'
	$Version = '17.4'


	function InstallVSCode
	{
		if (Chocolatized 'vscode')
		{
			WriteOK 'VSCode is already installed'
			return
		}

		Chocolatize 'vscode'

		$0 = 'C:\Program Files\Microsoft VS Code\bin'
		if (Test-Path $0)
		{
			# path will be added to Machine space but it isn't there yet
			# so temporarily fix path so we can install add-ons
			$env:PATH = (($env:PATH -split ';') -join ';') + ";$0"

			Highlight 'Adding VSCode extensions...'
			code --install-extension alexkrechik.cucumberautocomplete
			code --install-extension anseki.vscode-color
			code --install-extension eg2.tslint
			code --install-extension hediet.vscode-drawio
			code --install-extension ionutvmi.reg
			code --install-extension AykutSarac.jsoncrack-vscode
			code --install-extension mikeburgh.xml-format
			code --install-extension ms-azuretools.vscode-docker
			code --install-extension ms-python.python
			code --install-extension ms-vscode-remote.remote-wsl
			code --install-extension ms-dotnettools.csharp
			code --install-extension ms-vscode.powershell
			code --install-extension jebbs.plantuml
			code --install-extension sonarsource.sonarlint-vscode
			code --install-extension vscode-icons-team.vscode-icons
			code --install-extension snyk-security.vscode-vuln-cost	
			# git
			code --install-extension donjayamanne.githistory
			code --install-extension GitHub.vscode-pull-request-github
			# swagger
			code --install-extension Arjun.swagger-viewer
			code --install-extension 42Crunch.vscode-openapi
			code --install-extension mermade.openapi-lint
			# thunder client is a Postman alternative built into vscode
			code --install-extension rangav.vscode-thunder-client			
		}
	}
	
	function InstallVisualStudio
	{
		$0 = "C:\Program Files\Microsoft Visual Studio\$Year"
		$cmn = Test-Path (Join-Path $0 'Community\Common7\IDE\devenv.exe')
		$pro = Test-Path (Join-Path $0 'Professional\Common7\IDE\devenv.exe')
		$ent = Test-Path (Join-Path $0 'Enterprise\Common7\IDE\devenv.exe')
		if ($cmn -or $pro -or $ent)
		{
			WriteOK "Visual Studio $Year is already installed"
			return
		}

		$sku = 'professional'
		if ($Enterprise) { $sku = 'enterprise' }
		elseif ($Community) { $sku = 'community' }

		HighTitle "Visual Studio $Year ($sku)"
		Highlight '... This will take a few minutes'

		# download the installer
		$bits = "vs_$sku`_$Year`_$Version"
		DownloadBootstrap "$bits`.zip" $env:TEMP

		# run the installer
		& "$($env:TEMP)\$bits`.exe" --passive --config "$($env:TEMP)\vs_$sku`.vsconfig"

		Write-host '... Please wait for the installation to complete' -Fore Cyan
		Write-Host '... When complete, rerun this script using the -Extensions parameter' -Fore Cyan
	}


	function InstallVSExtensions
	{
		HighTitle 'Visual Studio Extensions'

		# MS Marketplace no longer allows anonymous downloads so we've packaged our own

		###
		### See readme.txt in the vs_extensions Zip file for links to each installer
		###

		DownloadBootstrap "vs_extensions_$Year.zip" $env:TEMP

		$root = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
		$installer = "$root\Common7\IDE\vsixinstaller.exe"

		InstallVsix $installer 'EditorGuidelines' 	# PaulHarrington.EditorGuidelines
		InstallVsix $installer 'InstallerProjects' 	# VisualStudioClient.MicrosoftVisualStudio2022InstallerProjects
		InstallVsix $installer 'MarkdownEditor' 	# Github
		InstallVsix $installer 'SonarLint' 			# SonarSource.SonarLintforVisualStudio2022
		InstallVsix $installer 'SpecFlow'			# TechTalkSpecFlowTeam.SpecFlowForVisualStudio2022
		InstallVsix $installer 'VSColorOutput'		# MikeWard-AnnArbor.VSColorOutput64
		InstallVsix $installer 'VSTextMacros-1.18'	# XavierPoinas.TextMacrosforVisualStudio201220132015

		Write-Host
		WriteWarn '... Wait a couple of minutes for the VSIXInstaller processes to complete before starting VS'
		WriteWarn '... These can be monitored in Task Manager; wait until they disappear'
	}


	function InstallVsix
	{
		param($installer, $name)
		WriteWarn "... installing $name extension in the background"
		$vsix = "$($env:TEMP)\$name`.vsix"
		& $installer /quiet /norepair $vsix
	}
}
Process
{
	if ($Code)
	{
		InstallVSCode
	}
	elseif ($Extensions)
	{
		InstallVSExtensions
	}
	else
	{
		Write-Host '*** It is highly recommend that you close Visual Studio, VSCode, and Office apps'
		Read-Host '*** Press Enter to continue'

		Write-Host '... clearing the %TEMP% folder'
		Remove-Item -Path "$env:TEMP\*" -Force -Recurse -ErrorAction:SilentlyContinue

		InstallCurl
		InstallVisualStudio
	}
}
