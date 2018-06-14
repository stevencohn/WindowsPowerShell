<#
.SYNOPSIS
Returns a VM configuration object of the specified .vmcx VM configuration
file even if the VM is not attached to a Hyper-V server.

.PARAMETER Json
Return a JSON representation of the VM configuration instead of an object.

.PARAMETER Path
Path to the .vmcx file. If this is a directory, returns the  first .vmcx found 
under that directory.
#>

using namespace System.IO

param (
	[Parameter(Mandatory=$true, Position=0)]
	[ValidateScript({
		if (!(Test-Path $_)) { Throw 'Path does not exist' }
		if ((Get-Item $_) -is [DirectoryInfo]) {
			$vmcx = (Get-ChildItem -Path $_ -Name '*.vmcx' -Recurse)
			if (($vmcx -eq $null) -or ($vmcx.Count -lt 1)) {
				Throw 'Path must contain a .vmcx configuration file'
			}
		}
		$true
	})]
	[string] $Path,

	[switch] $Json
	)

Begin
{
	# if path is VM host's machine path then the vmms service locks these files even
	# if the machine is not running so we copy to a temp location and read from there
	function CopyReadable
	{
		$root = [Path]::GetDirectoryName($Path)
		$name = [Path]::GetFileNameWithoutExtension($Path)
		$temp = [Path]::GetTempPath()

		# we need *.vmcx, *.vmgs, and *.vmrs
		Copy-Item (Join-Path $root "$name.vm*") $temp
		Set-Variable 'wild' (Join-Path $temp "$name.vm*") -Scope 'Script'

		return (Join-Path $temp "$name.vmcx")
	}

	function GetConfiguration ()
	{
		$dummyVhdPath = Join-Path $env:temp ([Path]::GetFileNameWithoutExtension($Path))

		$config = Compare-VM -Copy -Path $Path -GenerateNewId -VhdDestinationPath $dummyVhdPath

		if ($Json)
		{
			$config | ConvertTo-Json
		}
		else
		{
			$config
			#$config.VM
			#$config.VM.HardDrives
		}
	}
}
Process
{
	if ((Get-Item $Path) -is [DirectoryInfo])
	{
		$Path = Join-Path $Path ((Get-ChildItem -Path $Path -Name '*.vmcx' -Recurse) | Select -First 1)
	}

	if ($Path.StartsWith((Join-Path (Get-VMHost).VirtualMachinePath 'Virtual Machines')))
	{
		$Path = CopyReadable
	}

	GetConfiguration
}
End
{
	if ($wild -and (Test-Path $wild))
	{
		Remove-Item $wild -Force -Confirm:$false
	}
}
