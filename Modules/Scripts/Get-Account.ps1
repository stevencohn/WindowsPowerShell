<#
.SYNOPSIS
Report the account information for the given username and specified domain.
get-account -username foo -domain bar
#>
param(
	$username = $(throw "Please specify a username"),
	$domain = $env:USERDOMAIN)

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