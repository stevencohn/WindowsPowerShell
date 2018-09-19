<#
.SYNOPSIS
Install minimal Microsoft build and test tools required for CI/CD.

.PARAMETER Force
To prevent these lightweight tools from being installed ontop of an
already configured developer machine with full tools, this script will
not make any changes (beyond adding vswhere) unless -Force is specified.

.PARAMETER Full
Install the full version of VS Enterprise instead of just the command line tools.

.PARAMETER VSWhere
Install just the vswhere tool and return its path. This overrides all
other switches.

.OUTPUTS
An object specifying the home and path of msbuild, mstest, vswhere, and
the .NET SDK. If -VsWhere is specified then only returns the path to vswhere.
#>

param(
	[switch] $Force,
	[switch] $Full,
	[switch] $VSWhereCommand
)

Begin
{
	function InstallVSWhere
	{
		# try to find vswhere.exe. ProgramData is open and can be found easily by all users
		$script:vswhere = Join-Path $env:ProgramData 'vswhere.exe'
		if (!(Test-Path $vswhere)) { $script:vswhere = '.\vswhere.exe' }
		if (!(Test-Path $vswhere)) { $script:vswhere = (Get-Command 'vswhere' -ErrorAction:SilentlyContinue).Source }

		# didn't find it so download it
		if (!$vswhere)
		{
			$0 = 'https://github.com/Microsoft/vswhere'
			[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
			$response = Invoke-WebRequest $0/releases/latest -Headers @{"Accept"="application/json"} -UseBasicParsing
			$version = ($response.Content | ConvertFrom-Json).tag_name
			$script:vswhere = Join-Path $env:ProgramData 'vswhere.exe'
			Invoke-WebRequest "$0/releases/download/$version/vswhere.exe" -OutFile $vswhere
		}
	}

	function InstallHelperTools
	{
		if ((Get-Command git -ErrorAction:SilentlyContinue) -eq $null)
		{
			choco install -y git
		}

		if ((Get-Command nuget -ErrorAction:SilentlyContinue) -eq $null)
		{
			choco install -y nuget.commandline
		}
	}

	function InstallFullVS
	{
		# download the installer
		Invoke-WebRequest "<url goes here!>/vs_Enterprise.exe" -OutFile C:\vs2017.exe

		# run the installer
		Start-Process -FilePAth C:\vs2017.exe '--add Microsoft.VisualStudio.Workload.NetWeb `
			--add Microsoft.VisualStudio.Workload.ManagedDesktop `
			--add Component.GitHub.VisualStudio `
			--add Microsoft.VisualStudio.Workload.NativeCrossPlat `
			--add Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended `
			--add Microsoft.VisualStudio.Workload.NetCoreTools `
			--add Microsoft.VisualStudio.Component.TestTools.Core `
			--add Microsoft.VisualStudio.Component.TestTools.WebLoadTest `
			--add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop `
			--add Microsoft.VisualStudio.Component.Windows10SDK.14393 `
			--add Microsoft.VisualStudio.Component.Windows10SDK.16299.Desktop `
			--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
			--add Microsoft.VisualStudio.Component.VC.ATLMFC `
			--add Microsoft.VisualStudio.Component.VC.ATL `
			--add Microsoft.VisualStudio.Component.VC.DiagnosticTools `
			--add Microsoft.Net.Component.4.7.SDK `
			--add Microsoft.Net.Component.4.7.TargetingPack `
			--add Microsoft.Net.Component.4.7.1.SDK `
			--add Microsoft.Net.Component.4.7.1.TargetingPack `
			--add Microsoft.VisualStudio.Component.Workflow `
			--includeRecommended `
			--quiet --wait' -Wait

		# delete the installer
		Remove-Item C:\vs2017.exe -Force -Confirm:$false
	}

	function InstallLiteVS
	{
		# MSBuild

		$where = "$vswhere -products Microsoft.VisualStudio.Product.BuildTools -property installationPath" 
		$script:msbuildHome = Invoke-Expression -Command $where

		if (!$msbuildHome)
		{
			choco install -y visualstudio2017buildtools
			$script:msbuildHome = Invoke-Expression -Command $where
		}

		# MSTest

		$where = "$vswhere -products Microsoft.VisualStudio.Product.TestAgent -property installationPath"
		$script:mstestHome = Invoke-Expression -Command $where

		if (!$mstestHome)
		{
			choco install -y visualstudio2017testagent
			$script:mstestHome = Invoke-Expression -Command $where
		}

		# SDK

		$0 = 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows'
		if (!(Test-Path $0)) { $0 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows' }
		$where = "Get-ChildItem '$0' | ? { `$_.Name -match 'v8.1$' } | Get-ItemPropertyValue -Name InstallationFolder"
		$script:sdkHome =  Invoke-Expression -Command $where

		if (!(Test-Path $0) -or !(Get-ChildItem $0 | ? { $_.Name -match 'v8.1$' }))
		{
			# need SDK 8.1 to install older version of .NET; can add 10.1 ontop of this
			choco install -y windows-sdk-8.1
			$script:sdkHome =  Invoke-Expression -Command $where
		}
	}
}
Process
{
	InstallVSWhere

	if ($VSWhereCommand)
	{
		return [PSCustomObject]@{ 'VSWhereCommand' = $vswhere; }
	}

	if (!$Force)
	{
		Write-Host "`n... Specify -Force to hide this prompt" -ForegroundColor DarkYellow
		$answer = Read-Host -Prompt '... Are you sure you want to install light-weight tools'
		if (($answer -ne 'y') -and ($answer -ne 'Y'))
		{
			exit 0
		}
	}

	InstallHelperTools

	if ($Full)
	{
		InstallFullVS
	}
	else
	{
		InstallLiteVS
	}

	[PSCustomObject]@{
		'MSBuildHome' = $msbuildHome;
		'MSBuildCommand' = Join-Path $msbuildHome 'MSBuild\15.0\Bin\MSBuild.exe';
		'MSTestHome' = $mstestHome;
		'MSTestCommand' = Join-Path $mstestHome 'Common7\IDE\mstest.exe';
		'VSWhereCommand' = $vswhere;
		'SDKHome' = $sdkHome;
	}
}
