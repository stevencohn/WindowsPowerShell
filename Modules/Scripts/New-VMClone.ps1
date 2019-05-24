<#
.SYNOPSIS
Create a new VM from a registered VM or an exported VM

.PARAMETER Checkpoint
Create a new checkpoint immediately after creating the new VM.

.PARAMETER Name
The name of the new VM to create.

.PARAMETER Path
The path of the VM files to import. Typically this folder contains the folders Snapshots,
Virtual Hard Disks, and Virtual Machines where Virtual Machines contains a GUID.vmcx
configuration file. Could instead specify the full path to a .vmcx file. This is generated
using Export-VM similar to Export-VM -Name 'Win10' -Path 'E:\BackupVMs'

Mutually exclusive with -Template.

.PARAMETER Memory
Number of bytes applied to memory parameters. This is applied directly to 
MemoryStartup, 80% of this is applied to MemoryMinimum, 200% of this is applied
to MemoryMaximum.

.PARAMETER Template
The name of the registered VM to clone, using it as a template.

Mutually exclusive with -Path.

.OUTPUTS
Returns the VM as a Microsoft.HyperV.PowerShell.VirtualMachine

.EXAMPLE
New-VMClone -Name 'cds-oracle' -Template 'Win10'

.EXAMPLE
New-VMClone -Name 'cds-oracle' -Path 'E:\BackupVMs\Win10' -Checkpoint

.EXAMPLE
[SMC] This one works most reliably, after using the Export-VM command shown above:
New-VMClone -Name 'cds-oracle' -Path 'E:\BackupVMs\Win10\Virtual Machines\4FD97BB5-5CD5-4439-BBFF-498B0A5B3CE9.vmcx' -Verbose

.EXAMPLE
New-VMClone -Name 'cds-oracle' -Template 'Win10' -Memory 12GB

DynamicMemory is enabled
MemoryStartup is set to 12GB
MemoryMinimum is set to 9.6GB
MemoryMaximum is set to 24GB
#>

using namespace System.IO

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[Parameter(Position=0, Mandatory=$true, HelpMessage='Enter the name of the VM to create')]
	[ValidateScript({
		if ([bool](Get-VM $_ -ErrorAction SilentlyContinue) -ne $true) { $true } else {
			Throw "VM ""${_}"" already exists"
		}
	})]
	[string] $Name,

	[Parameter(Mandatory=$true, ParameterSetName='import')]
	[ValidateScript({
		if (!(Test-Path $_)) { Throw 'Path does not exist' }
		if ((Get-Item $_) -is [DirectoryInfo]) {
			$vmcx = (Get-ChildItem -Path $_ -Name '*.vmcx' -Recurse)
			if (($vmcx -eq $null) -or ($vmcx.Count -ne 1)) {
				Throw 'Path must contain exactly one .vmcx file or specify the full path to a .vmcx'
			}
		}
		$true
	})]
	[string] $Path,

	[Int64] $Memory,

	[Parameter(Mandatory=$true, ParameterSetName='clone')]
	[ValidateScript({
		if ((Get-VM $_ -ErrorAction SilentlyContinue) -ne $null) { $true } else {
			Throw "Template VM ""${_}"" does not exist"
		}
	})]
	[string] $Template,

	[switch] $Checkpoint
	)

Begin
{
	function ImportVM ($config)
	{
		$vmpath, $vhdpath = Get-VMHost | % { $_.VirtualMachinePath, $_.VirtualHardDiskPath }

		# place disk in its own folder to avoid duplicate name collisions
		$vhdpath = Join-Path $vhdpath $Name

		Write-Verbose "... importing $config"
		$ProgressPreference = 'SilentlyContinue'

		if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
		{
			Write-Host "Import-VM -Path $config -GenerateNewId -Copy -VirtualMachinePath $vmpath " + `
				"-VhdDestinationPath $vhdpath -SnapshotFilePath $vhdpath -SmartPagingFilePath $vhdpath" -ForegroundColor DarkYellow
		}

		$vm = Import-VM -Path $config -GenerateNewId -Copy `
			-VirtualMachinePath $vmpath -VhdDestinationPath $vhdpath `
			-SnapshotFilePath $vhdpath -SmartPagingFilePath $vhdpath

		if (!$vm)
		{
			throw 'Error creating VM'
		}

		# rename the VM
		Write-Verbose "... renaming VM to $Name"
		$vm | Rename-VM -NewName $Name

		# rename disks to match VM name
		$disks = Get-VMHardDiskDrive -VMName $Name
		foreach ($disk in $disks)
		{
			$diskroot = [Path]::GetDirectoryName($disk.Path)
			$extension = [Path]::GetExtension($disk.Path)

			$diskname = "{0}_{1}_{2}_{3}{4}" -f $disk.VMName, $disk.ControllerType, `
				$disk.ControllerNumber, $disk.ControllerLocation, $extension

			$diskPath = Join-Path $diskroot $diskname

			Write-Verbose "... renaming disk to $diskPath"
			Rename-Item $disk.Path $diskPath

			Write-Verbose "... setting VM disk to $diskPath"
			$ct = $disk.ControllerType
			$cl = $disk.ControllerLocation
			$cn = $disk.ControllerNumber

			# note this command doesn't like to be split across multiple lines!
			Set-VMHardDiskDrive -VMName $Name -Path $diskPath -ControllerType $ct -ControllerNumber $cn -ControllerLocation $cl
		}

		$vm
	}
}
Process
{
	if ($PSCmdlet.ParameterSetName -eq 'import')
	{
		$config = $Path
		if ((Get-Item $config) -is [DirectoryInfo])
		{
			$config = Join-Path $path ((Get-ChildItem -Path $config -Name '*.vmcx' -Recurse) | Select -First 1)
		}
	}
	else
	{
		$vm = (Get-VM $Template)
		$id = $vm.Id.ToString().ToUpper()
		$config = Join-Path $vm.Path (Get-ChildItem -Path $vm.Path -Name "$id`*.vmcx" -Recurse)
	}

	$vm = (ImportVM $config)

	if ($Memory)
	{
		Set-VMMemory -VM $vm -DynamicMemoryEnabled $true -StartupBytes $Memory `
			-MinimumBytes ($Memory * 0.8) -MaximumBytes ($Memory * 2)
	}

	if ($Checkpoint)
	{
		Write-Verbose '... creating checkpoint'

		if ($vm.CheckpointType -eq 'Disabled')
		{
			Set-VM -VM $vm -CheckpointType 'Standard'
		}

		$vm | Checkpoint-VM
	}

	$vm
}
