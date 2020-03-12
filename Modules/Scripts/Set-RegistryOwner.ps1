<#
.SYNOPSIS
Set full-access ownership of a specified Registry key.

.PARAMETER Hive
The hive name, such as HKLM, HKCU, etc.

.PARAMETER Key
The key path below the specified hive.

.PARAMETER Recurse
Take ownership of specified key and all subkeys, default is True

.PARAMETER SID
The SID of the user to grant ownership, default is current user.

.PARAMETER Verbose
Show verbose output.

.PARAMETER WhatIf
Show actions but do not perform them.

.EXAMPLE
# take ownership of all Compressed Folders keys (e.g. replacing with 7-Zip)
Set-RegistryOwner 'HKCR' 'CLSID\{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31}';
Set-RegistryOwner 'HKCR' 'CLSID\{0CD7A5C0-9F37-11CE-AE65-08002B2E1262}';
Set-RegistryOwner 'HKLM' 'SOFTWARE\WOW6432Node\Classes\CLSID\{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31}';
Set-RegistryOwner 'HKLM' 'SOFTWARE\WOW6432Node\Classes\CLSID\{0CD7A5C0-9F37-11CE-AE65-08002B2E1262}';

# remove all Compressed Folders keys; back-ticks required to escape curly braces
Remove-Item -Path Registry::HKEY_CLASSES_ROOT\CLSID\`{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31`} -Force -Recurse;
Remove-Item -Path Registry::HKEY_CLASSES_ROOT\CLSID\`{0CD7A5C0-9F37-11CE-AE65-08002B2E1262`} -Force -Recurse;
Remove-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\CLSID\`{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31`} -Force -Recurse;
Remove-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\CLSID\`{0CD7A5C0-9F37-11CE-AE65-08002B2E1262`} -Force -Recurse;

.NOTES
http://shrekpoint.blogspot.ru/2012/08/taking-ownership-of-dcom-registry.html
http://www.remkoweijnen.nl/blog/2012/01/16/take-ownership-of-a-registry-key-in-powershell/
https://powertoe.wordpress.com/2010/08/28/controlling-registry-acl-permissions-with-powershell/
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[Parameter(Mandatory=$true, Position=0)]
	[string] $Hive,

	[Parameter(Mandatory=$true, Position=1)]
	[string] $Key,

	[System.Security.Principal.SecurityIdentifier] $SID,
	[switch] $Recurse = $true
)

Begin
{
	function EscalatePrivileges ()
	{
		# get SeTakeOwnership, SeBackup and SeRestore privileges, script needs Admin privilege
		$import = '[DllImport("ntdll.dll")] public static extern int RtlAdjustPrivilege(ulong a, bool b, bool c, ref bool d);'
		$ntdll = Add-Type -Member $import -Name NtDll -PassThru
		$privileges = @{ SeTakeOwnership = 9; SeBackup = 17; SeRestore = 18 }
		foreach ($i in $privileges.Values)
		{
			$null = $ntdll::RtlAdjustPrivilege($i, 1, 0, [ref]0)
		}
	}

	function TakeOwnershihp ($root, $key, $recurseLevel = 0)
	{
		$check = Invoke-Expression "[Microsoft.Win32.Registry]::$($root).OpenSubKey('$($key)')"
		if ($check -eq $null)
		{
			Write-Verbose 'Key not found'
			return
		}

		Write-Verbose('Taking ownership of {0}:\{1}' -f $root, $key)

		# get ownerships of key - it works only for current key
		$acl = New-Object System.Security.AccessControl.RegistrySecurity
		$acl.SetOwner($SID)
		$item = [Microsoft.Win32.Registry]::$root.OpenSubKey($key, 'ReadWriteSubTree', 'TakeOwnership')
		
		if ($WhatIfPreference) { Write-Host('Taking ownership of {0}:\{1}' -f $root, $key) -ForegroundColor DarkGray }
		else { $item.SetAccessControl($acl) }

		# enable inheritance of permissions (not ownership) for current key from parent
		$acl.SetAccessRuleProtection($false, $false)

		if ($WhatIfPreference) { Write-Host('Enable inheritance of {0}:\{1}' -f $root, $key) -ForegroundColor DarkGray }
		else { $item.SetAccessControl($acl) }

		# only for top-level key, change permissions for current key and propagate it for subkeys
		# to enable propagations for subkeys, it needs to execute Steps 2-3 for each subkey (Step 5)
		if ($recurseLevel -eq 0)
		{
			$item2 = $item.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
			$rule = New-Object System.Security.AccessControl.RegistryAccessRule($sid, 'FullControl', 'ContainerInherit', 'None', 'Allow')
			$acl.ResetAccessRule($rule)

			if ($WhatIfPreference) { Write-Host('Set write access to {0}:\{1}' -f $root, $key) -ForegroundColor DarkGray }
			else { $item2.SetAccessControl($acl) }
		}

		### Step 5 - recursively repeat steps 2-5 for subkeys
		if ($Recurse)
		{
			foreach ($subKey in $item.OpenSubKey('').GetSubKeyNames())
			{
				TakeOwnershihp $root ($key + '\' + $subKey) ($recurseLevel + 1)
			}
		}
	}
}
Process
{
	$elevated = (Test-Elevated -Action 'Take-RegKeyOwnership' -Warn)
	if ($elevated) { Write-Verbose 'Elevated' } else { Write-Verbose 'Not elevated' }

	if (!$SID)
	{
		$SID = Get-Account -Username $env:USERNAME -SID
		Write-Verbose ('SID of {0} is {1}' -f $env:USERNAME, $SID)
	}

	EscalatePrivileges

	switch -regex ($Hive)
	{
		'HKCU|HKEY_CURRENT_USER' { $root = 'CurrentUser' }
		'HKLM|HKEY_LOCAL_MACHINE' { $root = 'LocalMachine' }
		'HKCR|HKEY_CLASSES_ROOT' { $root = 'ClassesRoot' }
		'HKCC|HKEY_CURRENT_CONFIG' { $root = 'CurrentConfig' }
		'HKU|HKEY_USERS' { $root = 'Users' }
	}

	TakeOwnershihp $root $Key 0
}
