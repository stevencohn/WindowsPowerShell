<#
.SYNOPSIS
Report the account information for the given username and specified domain.

.DESCRIPTION
Can report on either a local user account or an ActiveDirectory account.

.PARAMETER Username
The account username to report.

.PARAMETER Domain
The ActiveDirectory domain to use. Default is $env:USERDOMAIN.

.PARAMETER SID
If specified then return only the Sid
#>

param(
	[string] $Username = $(throw "Please specify a username"),
	[string] $Domain = $env:USERDOMAIN,
	[switch] $SID
	)

Begin
{
	function GetLocalSid ()
	{
		$account = Get-LocalUser -Name $Username
		if (!$account) { Throw 'Account not found' }

		$account.SID
	}

	function ReportLocalUser ()
	{
		$account = Get-LocalUser -name $Username
		if (!$account) { Throw 'Account not found' }
	
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

	function GetDomainSid ()
	{
		$user = New-Object System.Security.Principal.NTAccount($Domain, $Username)
		if (!$user) { Throw 'Account not found' }

		$sidval = $user.Translate([System.Security.Principal.SecurityIdentifier]) 
		$sidval.Value
	}

	function ReportDomainUser ()
	{
		$found = $false
		$entry = New-Object System.DirectoryServices.DirectoryEntry('GC://' + $Domain)
		$searcher = New-Object System.DirectoryServices.DirectorySearcher($entry)
		$searcher.Filter = '(&((&(objectCategory=Person)(objectClass=User)))(samaccountname=' + $Username + '))'
		try
		{
			$searcher.FindAll() | % `
			{
				$properties = $_.GetDirectoryEntry().Properties
				#$properties
				Write-Host('Account Name : ' + $properties['sAMAccountName'].Value)
				Write-Host('Display Name : ' + $properties['displayName'].Value)
				Write-Host('Mail         : ' + $properties['mail'].Value)
				Write-Host('Telephone    : ' + $properties['telephoneNumber'].Value)

				$lastset = [datetime]::FromFileTimeUtc((ConvertADSLargeInteger $properties['pwdLastSet'].Value))
				Write-Host('Pwd last set : ' + $lastset)

				#Write-Host('Member of    : ' + $properties['memberOf'].Value)

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


	function ConvertADSLargeInteger([object] $adsLargeInteger)
	{
		$highPart = $adsLargeInteger.GetType().InvokeMember("HighPart", [System.Reflection.BindingFlags]::GetProperty, $null, $adsLargeInteger, $null)
		$lowPart  = $adsLargeInteger.GetType().InvokeMember("LowPart",  [System.Reflection.BindingFlags]::GetProperty, $null, $adsLargeInteger, $null)
		$bytes = [System.BitConverter]::GetBytes($highPart)
		$tmp   = [System.Byte[]]@(0,0,0,0,0,0,0,0)
		[System.Array]::Copy($bytes, 0, $tmp, 4, 4)
		$highPart = [System.BitConverter]::ToInt64($tmp, 0)
		$bytes = [System.BitConverter]::GetBytes($lowPart)
		$lowPart = [System.BitConverter]::ToUInt32($bytes, 0)
		return $lowPart + $highPart
	}
}
Process
{
	if ($Domain -eq $env:COMPUTERNAME)
	{
		if ($SID) { GetLocalSid } else { ReportLocalUser }
	}
	else
	{
		if ($SID) { GetDomainSid } else { ReportDomainUser }
	}
}
