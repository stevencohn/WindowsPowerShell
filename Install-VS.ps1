<#
.SYNOPSIS
Standalone script to install Visual Studio or VSCode and their extensions.

All parameters are mutually exlusive!

.PARAMETER Code
Install VSCode; default is to install Visual Studio

.PARAMETER Community
Install Visual Studio Community; default is to install Professional

.PARAMETER Enterprise
Install Visual Studio Enterprise; default is to install Professional

.PARAMETER Extensions
Install general VSIX extenions
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[Parameter(ParameterSetName='cd', Mandatory=$false)] [switch] $Code,
	[Parameter(ParameterSetName='en', Mandatory=$false)] [switch] $Enterprise,
	[Parameter(ParameterSetName='cm', Mandatory=$false)] [switch] $Community,
	[Parameter(ParameterSetName='ex', Mandatory=$false)] [switch] $Extensions
)

Begin
{
	. $PSScriptRoot\common.ps1

	$Year = '2022'
	$Version = '17.3'


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
			code --install-extension ionutvmi.reg
			code --install-extension mikeburgh.xml-format
			code --install-extension ms-azuretools.vscode-docker
			code --install-extension ms-python.python
			code --install-extension ms-vscode-remote.remote-wsl
			code --install-extension ms-vscode.csharp
			code --install-extension ms-vscode.powershell
			#code --install-extension msjsdiag.debugger-for-chrome
			code --install-extension jebbs.plantuml
			code --install-extension sonarlint
			code --install-extension vscode-icons-team.vscode-icons
			# Vuln Cost - Security Scanner for VS Code
			code --install-extension snyk-security.vscode-vuln-cost	
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
		$pro = Test-Path (Join-Path $0 'Professional\Common7\IDE\devenv.exe')
		$ent = Test-Path (Join-Path $0 'Enterprise\Common7\IDE\devenv.exe')
		if ($pro -or $ent)
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
		# https://marketplace.visualstudio.com/items?itemName=PaulHarrington.EditorGuidelines
		# https://marketplace.visualstudio.com/items?itemName=SonarSource.SonarLintforVisualStudio2022
		# https://marketplace.visualstudio.com/items?itemName=SonarSource.SonarLintforVisualStudio2022
		# https://marketplace.visualstudio.com/items?itemName=TechTalkSpecFlowTeam.SpecFlowForVisualStudio2022
		# https://marketplace.visualstudio.com/items?itemName=MikeWard-AnnArbor.VSColorOutput64

		DownloadBootstrap "vs_extensions_$Year.zip" $env:TEMP

		$root = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
		$installer = "$root\Common7\IDE\vsixinstaller.exe"

		InstallVsix $installer 'EditorGuidelines'
		InstallVsix $installer 'MarkdownEditor'
		InstallVsix $installer 'SonarLint'
		InstallVsix $installer 'SpecFlow'
		InstallVsix $installer 'VSColorOutput'

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
		Write-Host '*** This installer will require a system reboot'
		Write-Host '*** It is highly recommend that you close Visual Studio, VSCode, and Office apps'
		Read-Host '*** Press Enter to continue'

		Write-Host '... clearing the %TEMP% folder'
		Remove-Item -Path "$env:TEMP\*" -Force -Recurse -ErrorAction:SilentlyContinue

		InstallCurl
		InstallVisualStudio
	}
}
