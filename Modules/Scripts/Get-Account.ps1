<#
.SYNOPSIS
Report the account information for the given username and specified domain.

.DESCRIPTION
Can report on either a local user account or an ActiveDirectory account.

.PARAMETER All
Report all local users.

.PARAMETER Username
The account username to report. Default is $env:USERNAME.

.PARAMETER Domain
The ActiveDirectory domain to use. Default is $env:USERDOMAIN.

.PARAMETER SID
If specified then return only the Sid
#>

param(
	[string] $Username = $env:USERNAME,
	[string] $Domain = $env:USERDOMAIN,
	[switch] $SID,
	[switch] $All
	)

Begin
{
	$script:LabelWidth = 15

	# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	# Helpers...

	function ConvertFileTime
	{
		param($value)
		try {
			return [datetime]::FromFileTimeUtc($value)
		}
		catch {
			return '<error in ConvertFileTime>'
		}
	}

	function ConvertADSLargeInteger
	{
		param([object] $adsLargeInteger)
		try {
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
		catch {
			return '<error in ConvertADSLargeInteger>'
		}
	}

	function FormatEnabledString
	{
		param($user, $value)
		if ($user.Enabled) {
			"$($PSStyle.BrightWhite)$value$($PSStyle.Reset)"
		} else {
			"$($PSStyle.BrightBlack)$value$($PSStyle.Reset)"
		}
	}

	function WriteHanging
	{
		param(
			[Parameter(Mandatory)] [string]$Label,
			[Parameter(Mandatory)] [string[]]$Items,
			[ConsoleColor]$Forecolor = 'DarkGray'
		)

		$Label = ("{0,-$LabelWidth}: " -f $Label)
		$Label | Write-Host -NoNewline

		$indent = $Label.Length
		$width = $host.UI.RawUI.WindowSize.Width - $indent
		$margin = ' ' * $indent

		$line = '' # first line is already prefixed with Label
		foreach ($item in $items)
		{
			$item = $item.Trim()
			if ($item) {
				if ($line.Length + $item.Length + 2 -gt $width) {
					Write-Host $line -ForegroundColor $Forecolor
					$line = $margin # subsequent lines get a margin prefix
				} else {
					$line = $line.Trim().Length -eq 0 ? "$line$item" : "$line, $item"
				}
			}
		}

		if ($line.Length -gt $margin.Length) {
			Write-Host $line -ForegroundColor $Forecolor
		}
	}

	function GetLocalSid
	{
		$account = Get-LocalUser -Name $Username
		if (!$account) { Throw 'Account not found' }

		$account.SID
	}

	# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	# Reporters...

	function ReportLocalUser
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

	function GetDomainSid
	{
		$user = New-Object System.Security.Principal.NTAccount($Domain, $Username)
		if (!$user) { Throw 'Account not found' }

		$sidval = $user.Translate([System.Security.Principal.SecurityIdentifier]) 
		$sidval.Value
	}

	function ReportDomainUser
	{
		$formatter = '{0,-15}: {1}'
		$entry = New-Object System.DirectoryServices.DirectoryEntry('GC://' + $Domain)
		$searcher = New-Object System.DirectoryServices.DirectorySearcher($entry)
		$searcher.Filter = '(&((&(objectCategory=Person)(objectClass=User)))(samaccountname=' + $Username + '))'

		$found = try
		{
			$searcher.FindAll() | % `
			{
				$properties = $_.properties

				Write-Host
				Write-Host ('-' * 80)

				($formatter -f 'Account','') | Write-Host -NoNewline
				$properties.samaccountname[0] | Write-Host -ForegroundColor Cyan -NoNewline
				" ($($properties.adspath[0]))" | Write-Host -ForegroundColor DarkGray

				($formatter -f 'Principal name',$properties.userprincipalname[0]) | Write-Host
				($formatter -f 'Display name',$properties.displayname[0]) | Write-Host

				$title = $properties.title[0]
				if (![string]::IsNullOrWhiteSpace($title)) {
					($formatter -f 'Title',"$($PSStyle.Italic)$title$($PSStyle.Reset)") | Write-Host -NoNewline
					$att = $properties.extensionattribute8[0] # I think this is worker|manager|something|something...
					if (![string]::IsNullOrWhiteSpace($att)) { Write-Host " ($att)" -NoNewline }
					$company = $properties.company[0]
					if (![string]::IsNullOrWhiteSpace($company)) { Write-Host " [$company]" -NoNewline }
					Write-Host
				}

				$dept = $properties.department[0]
				$group = $properties.extensionattribute9[0]
				if (![string]::IsNullOrWhiteSpace($group)) { $dept = "$dept, $group" }
				$org = $properties.extensionattribute3[0]
				if (![string]::IsNullOrWhiteSpace($org)) { $dept = "$dept, $org" }
				($formatter -f 'Department',$dept) | Write-Host

				$manager = [string]($properties.manager[0])
				if (!([String]::IsNullOrWhiteSpace(($manager)))) {
					if ($manager.StartsWith('CN=')) {
						$manager = $manager.Split(',')[0].Split('=')[1]
						($formatter -f 'Manager',$manager) | Write-Host
					}
				}
	
				$mail = $properties.mail[0]
				($formatter -f 'Mail',$mail) | Write-Host

				if ($properties.proxyaddresses.count -gt 0) {
					$aliases = @()
					$properties.proxyaddresses | foreach {
						$alias = $_.ToLower().StartsWith('smtp:') ? $_.Substring(5) : $_
						if ($alias -ne $mail) { $aliases += $alias }
					}
					if ($aliases.count -gt 0) {
						WriteHanging -Label 'Mail aliases' -Items ($aliases | sort)
					}
				}

				$address = "{0}, {1} {2}, {3}, {4}" -f $properties.streetaddress[0],$properties.l[0],$properties.st[0],$properties.postalcode[0],$properties.c[0]
				($formatter -f 'Address',$address) | Write-Host

				($formatter -f 'Telephone',$properties.telephonenumber[0]) | Write-Host

				$mobile = $properties.mobile[0]
				if (![string]::IsNullOrWhiteSpace($mobile)) { ($formatter -f 'Mobile',$mobile) | Write-Host }

				$lastlogin = ConvertFileTIme $properties.lastlogontimestamp[0]
				($formatter -f 'Last login',$lastlogin) | Write-Host

				$lastset = ConvertFileTime $properties.pwdlastset[0]
				($formatter -f 'Pwd last set',$lastset) | Write-Host -NoNewline
				$days = ((Get-Date) - (Get-Date $lastset)).Days
				$color = if ($days -lt 20) { 'Green' } elseif ($days -lt 60) { 'Yellow' } else { 'Red' }
				Write-Host " ($days days ago)" -ForegroundColor $color

				($formatter -f 'Last modified',$properties.whenchanged[0]) | Write-Host # no conversion needed, already string!

				$sid = New-Object System.Security.Principal.SecurityIdentifier($properties.objectsid[0], 0)
				($formatter -f 'SID',$sid) | Write-Host

				if ($properties.directreports.count -gt 0) {
					$reports = @()
					$properties.directreports | foreach { 
						if ($_.StartsWith('CN=')) { $reports += $_.split(',')[0].split('=')[1] }
					}
					if ($reports.count -gt 0) {
						Write-Host
						WriteHanging -Label 'Direct reports' -Items ($reports | sort)
					}
				}

				if ($properties.memberof.count -gt 0) {
					$ships = @()
					$properties.memberof | foreach { 
						if ($_.StartsWith('CN=')) { $ships += $_.split(',')[0].split('=')[1] }
					}
					if ($ships.count -gt 0) {
						Write-Host
						WriteHanging -Label 'Member of' -Items ($ships | sort)
					}
				}

				$true
			}
		}
		catch
		{
			write-host $_.Exception.Message -ForegroundColor Red
			$true
		}

		if (!$found) {
			Write-Host ... Count not find user "$domain\$username" -ForegroundColor Yellow
		}
	}


	function ReportAllUsers
	{
		Get-LocalUser | `
			Select-Object Name, FullName, Enabled, PasswordExpires, Description, Sid | `
			Format-Table `
				@{ Label = 'Name'; Expression = { FormatEnabledString $_ $_.Name } },
				@{ Label = 'FullName'; Expression = { FormatEnabledString $_ $_.FullName } },
				@{ Label = 'Enabled'; Expression = { FormatEnabledString $_ $_.Enabled } },
				@{
					Label = 'PasswordExpires'
					Expression = { FormatEnabledString $_ $_.PasswordExpires.ToShortDateString() }
				},
				@{
					Label = 'Description'
					Expression = { FormatEnabledString $_ (($_.Description.ToCharArray() | select -First 30) -join '') }
				},
				@{ Label = 'Sid'; Expression = { FormatEnabledString $_ $_.Sid } } `
				-AutoSize
	}
}
Process
{
	if ($All)
	{
		ReportAllUsers
	}
	elseif ($Domain -eq $env:COMPUTERNAME)
	{
		if ($SID) { GetLocalSid } else { ReportLocalUser }
	}
	else
	{
		if ($SID) { GetDomainSid } else { ReportDomainUser }
	}
}
<#
	if ($System)
	{
		# Get SID from username
		$objUser = New-Object System.Security.Principal.NTAccount("SYSTEM") 
		$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier]) 
		ReportLocalUser -userSID $strSID.Value
		return
		# # Get username from SID
		# $objSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18") 
		# $objUser = $objSID.Translate( [System.Security.Principal.NTAccount]) 
		# $objUser.Value
	}
#>
