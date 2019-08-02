<#
Computer\HKEY_CURRENT_USER\Software\Policies\Microsoft\OneDrive
Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager
#>

# check is personal account is available

Begin
{
	function GetSyncRootPath ($parentName)
	{
		$key = Get-Item "$name\UserSyncRoots"
		if ($key)
		{
			$parts = $name.Split('!')
			if ($parts.Count -gt 1)
			{
				$path = $key.GetValue($parts[1], $null)
				return $path
			}
		}

		return $null
	}
}
Process
{
	$foundBusiness = $false
	$foundPersonal = $false

	$0 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager'

	Get-ChildItem $0 | % { $_.Name.Replace('HKEY_LOCAL_MACHINE', 'HKLM:') } | % `
	{
		$name = $_

		if ($name -match 'Personal')
		{
			$path = GetSyncRootPath($name)
			if ($path)
			{
				Write-Host "... found Personal folder $path"
				$foundPersonal = $true
			}
		}
		elseif ($name -match 'Business')
		{
			$path = GetSyncRootPath($name)
			if ($path)
			{
				Write-Host "... found Business folder $path"
				$foundBusiness = $true
			}
		}
	}

	if (-not $foundPersonal)
	{
		Write-Host '... did not find personal account' -ForegroundColor Yellow
		Write-Host '... Right-click OneDrive tray icon and add account' -ForegroundColor DarkYellow
		return
	}

	if (-not $foundBusiness)
	{
		Write-Host '... did not find business account; nothing further to do'
		return
	}

	# check if personal sync is enabled

	$0 = 'HKCU:\Software\Policies\Microsoft\OneDrive';
	$key = Get-Item $0
	$disabled = $key.GetValue('DisablePersonalSync', $null)
	if ($disabled -eq $null)
	{
		Write-Host '... OneDrive key not found in Registry. Is OneDrive installed?' -ForegroundColor Yellow
		return
	}
	elseif ($disabled -ne 0)
	{
		Write-Host '... enabling personal sync'
		Set-ItemProperty $0 -Name 'DisablePersonalSync' -value 0 -Type Dword
	}
	else
	{
		Write-Host '... personal sync is enabled'
	}
}
