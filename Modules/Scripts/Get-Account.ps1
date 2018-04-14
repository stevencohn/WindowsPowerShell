<#
.SYNOPSIS
Report the account information for the given username and specified domain.

.DESCRIPTION
Can report on either a local user account or an ActiveDirectory account.

.PARAMETER username
The account username to report.

.PARAMETER domain
The ActiveDirectory domain to use. Default is $env:USERDOMAIN.
#>
param(
	$username = $(throw "Please specify a username"),
	$domain = $env:USERDOMAIN)

if ($domain -eq $env:COMPUTERNAME)
{
	# local computer account...

	$account = Get-LocalUser -name $username
	if (!$account)
	{
		Throw 'Account not found'
	}

	Write-Host('Account Name     : ' + $account.Name)
	Write-Host('Display Name     : ' + $account.FullName)
	Write-Host('Description      : ' + $account.Description)
	Write-Host('Principal Source : ' + $account.PrincipalSource)
	Write-Host('Expires          : ' + $account.AccountExpires)
	Write-Host('Last Logon       : ' + $account.LastLogon)
	Write-Host('Password Set     : ' + $account.PasswordLastSet)
	Write-Host('Password Locked  : ' + (-not $account.UserMayChangePassword))
	Write-Host('Enabled          : ' + $account.Enabled)
	Write-Host('SID              : ' + $account.SID)

	$groups = @()
	Get-LocalGroup | % `
	{
		if ((get-localgroupmember $_.Name | select -property name | ? { $_ -match "\\$username" }) -ne $null)
		{
			$groups += $_.Name
		}
	}
	write-host("Groups           : {0}" -f ($groups -join ', '))
}
else
{
	# ActiveDirectory account...

	$found = $false
	$entry = New-Object System.DirectoryServices.DirectoryEntry('GC://' + $domain)
	$searcher = New-Object System.DirectoryServices.DirectorySearcher($entry)
	$searcher.Filter = '(&((&(objectCategory=Person)(objectClass=User)))(samaccountname=' + $username + '))'
	try
	{
		$searcher.FindAll() | % `
		{
			$properties = $_.GetDirectoryEntry().Properties
			Write-Host('Account Name : ' + $properties['sAMAccountName'].Value)
			Write-Host('Display Name : ' + $properties['displayName'].Value)
			Write-Host('Mail         : ' + $properties['mail'].Value)
			Write-Host('Telephone    : ' + $properties['telephoneNumber'].Value)

			$manager = [string]($properties['manager'].Value)
			if (!([String]::IsNullOrEmpty($manager))) {
				if ($manager.StartsWith('CN=')) {
					$manager = $manager.Split(',')[0].Split('=')[1]
					Write-Host('Manager      : ' + $manager)
				}
			}

			$found = $true
		}
	}
	catch
	{
	}

	if (!$found)
	{
		Write-Host ... Count not find user "$domain\$username" -ForegroundColor Yellow
	}
}
