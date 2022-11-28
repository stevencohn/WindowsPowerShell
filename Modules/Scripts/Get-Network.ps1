<#
.SYNOPSIS
Displays network adapter information and optionally WiFi profiles with clear text passphrases.
Can be used to determine the most likely candidate for the active Internet-specific network
adapter. Only connected IP adapters are considered; all other adpaters such as tunneling and
loopbacks are ignored.

.PARAMETER Addresses
Return a @(list) of addresses

.PARAMETER Preferred
Only return the preferred network address without report bells and whistles.

.PARAMETER Verbose
Display extra information including MAC addres and bytes sent/received.

.PARAMETER WiFi
Show detailed WiFi profiles include clear text passwords, highlighting
currently active SSID and open networks.
#>

using namespace System.Net
using namespace System.Net.NetworkInformation

[CmdletBinding()]

param(
	[switch] $preferred,	# just return the preferred address
	[switch] $addresses,	# return a list of host addresses
	[switch] $wiFi			# show detailed WiFi profiles
)

Begin
{
	$esc = [char]27

	function GetAllAddresses
	{
		$addresses = @()
		if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
		{
			[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | foreach `
			{
				$props = $_.GetIPProperties()

				$address = $props.UnicastAddresses `
					| where { $_.Address.AddressFamily -eq 'InterNetwork' } `
					| select -first 1 -ExpandProperty Address

				if ($address)
				{
					$addresses += $address.IPAddressToString
				}
			}
		}

		$addresses
	}

	function GetPreferredAddress
	{
		$prefs = @()
		if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
		{
			[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | foreach `
			{
				if (($_.NetworkInterfaceType -ne 'Loopback') -and ($_.OperationalStatus -eq 'Up'))
				{
					$props = $_.GetIPProperties()
 
					$address = $props.UnicastAddresses `
						| where { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty Address

					$DNSServer = $props.DnsAddresses `
						| where { $_.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty IPAddressToString

					if ($address -and $DNSServer)
					{
						$prefs += $address.IPAddressToString
					}
				}
			}
		}

		if ($prefs.Length -gt 0)
		{
			return $prefs[0]
		}

		return $null
	}

	function CollectInformation
	{
		$preferred = $null
		$items = @()
		if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
		{
			$SSID = $null
			(netsh wlan show interfaces | select-string '\sSSID') -match '\s{2,}:\s(.*)' | Out-Null
			if ($Matches -and $Matches.Count -gt 1)
			{
				$SSID = $Matches[1].ToString()
			}

			[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | foreach `
			{
				if ($_.NetworkInterfaceType -ne 'Loopback')
				{
					$item = New-Object PSObject -Property @{
						Address         = $null
						PhysicalAddress = $_.GetPhysicalAddress().ToString()
						DNSServer       = $null
						Gateway         = $null
						Description     = $null
						DnsSuffix       = $null
						SSID            = $null
						BytesReceived   = 0
						BytesSent       = 0
						Status          = $_.OperationalStatus
						Type            = $_.NetworkInterfaceType
					}

					$props = $_.GetIPProperties()

					$item.Address = $props.UnicastAddresses `
						| where { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty Address

					$item.DNSServer = $props.DnsAddresses `
						| where { $_.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty IPAddressToString

					$item.Gateway = $props.GatewayAddresses `
						| where { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty Address

					$stats = $_.GetIPv4Statistics() | Select -first 1
					$item.BytesReceived = $stats.BytesReceived
					$item.BytesSent = $stats.BytesSent

					$item.Description = $_.Name + ', ' + $_.Description
					$item.DnsSuffix = $props.DnsSuffix
					if (![String]::IsNullOrWhiteSpace($item.DnsSuffix))
					{
						$item.Description += (', ' + $item.DnsSuffix)
					}

					if ($item.Type.ToString().StartsWith('Wireless') -and $SSID -and ($item.BytesReceived -gt 0))
					{
						$item.Description = (', ' + $SSID)
					}

					if (($item.Status -eq 'Up') -and $item.Address -and ($item.BytesReceived -gt 0))
					{
						if (!$preferred)
						{
							$preferred = $item
						}

						if (!$preffered.SSID)
						{
							$preferred.SSID = $SSID
						}
					}

					$items += $item
				}
			}
		}

		@{
			Preferred = $preferred
			Items = $items
		}
	}

	function ShowPreferred
	{
		param($preferred)
		Write-Host
		if ($preferred -eq $null)
		{
			Write-Host ('{0} Preferred address is unknown' -f $env:COMPUTERNAME) -ForegroundColor DarkGreen -NoNewline
		}
		else
		{
			Write-Host ("{0} Preferred address is {1}" -f $env:COMPUTERNAME, $preferred.Address) -ForegroundColor Green -NoNewline
		}

		if ($preferred.SSID)
		{
			Write-Host " | SSID:$($preferred.SSID)" -ForegroundColor DarkGreen -NoNewline
		}

		# make FQDN
		$domain = [IPGlobalProperties]::GetIPGlobalProperties().DomainName
		if ([String]::IsNullOrEmpty($domain)) { $domain = [Dns]::GetHostName() }
		$name = [Dns]::GetHostName()
		if ($name -ne $domain) { $name = $name + '.' + $domain }
		Write-Host " | HOST:$name" -ForegroundColor DarkGreen
	}

	function GetColorOf
	{
		param($item, $preferred)
		if ($item.Status -ne 'Up') { @{ foregroundcolor='DarkGray' } }
		elseif ($item.Address -eq $preferred.Address) { @{ foregroundcolor='Green' } }
		elseif ($item.Type -match 'Wireless') { @{ foregroundcolor='Cyan' } }
		elseif ($item.Description -match 'Bluetooth') { @{ foregroundcolor='DarkCyan' } }
		else { @{ } }
	}

	function ShowBasicInfo
	{
		param($info)
		Write-Host
		Write-Host 'Address         DNS Server      Gateway         Interface'
		Write-Host '-------         ----------      -------         ---------'
		$info.Items | foreach `
		{
			$line = ("{0,-15} {1,-15} {2,-15} {3}" -f $_.Address, $_.DNSServer, $_.Gateway, $_.Description)
			$hash = GetColorOf $_ $info.Preferred
			Write-Host $line @hash
		}
	}

	function ShowDetailedInfo
	{
		param($info)
		Write-Host
		Write-Host 'IP/DNS/Gateway   Interface Details'
		Write-Host '--------------   -----------------'
		$info.Items | foreach `
		{
			if ($_.PhysicalAddress) {
				for ($i = 10; $i -gt 0; $i -= 2) { $_.PhysicalAddress = $_.PhysicalAddress.insert($i, '-') }
			}

			$hash = GetColorOf $_ $info.Preferred

			Write-Host ("{0,-15}  {1}" -f $_.Address, $_.Description) @hash
			Write-Host ("{0,-15}  Physical Address.. {1}" -f $_.DNSServer, $_.PhysicalAddress) -ForegroundColor DarkGray
			Write-Host ("{0,-15}  Type.............. {1}" -f $_.Gateway, $_.Type) -ForegroundColor DarkGray

			if ($_.Status -eq 'Up')
			{
				Write-Host ("{0,16} Bytes Sent........ {1:N0}" -f '',$_.BytesSent) -ForegroundColor DarkGray
				Write-Host ("{0,16} Bytes Received.... {1:N0}" -f '',$_.BytesReceived) -ForegroundColor DarkGray

				if ($_.DnsSuffix)
				{
					Write-Host ("{0,16} DnsSuffix......... {1}" -f '',$_.DnsSuffix) -ForegroundColor DarkGray
				}
			}

			Write-Host
		}
	}

	function ShowWiFiProfiles
	{
		$path = Join-Path $env:temp 'wxpx'
		if (Test-Path $path)
		{
			Remove-Item $path\*.xml -Force -Confirm:$false
		}
		else
		{
			New-Item -ItemType Directory $path -Force | Out-Null
		}

		netsh wlan export profile folder=$path key=clear | Out-Null

		$profiles = @()
		Get-Item $path\Wi-Fi-*.xml | foreach `
		{
			[xml]$xml = Get-Content $_
			$pkg = $xml.WLANProfile
			$key = $pkg.MSM.Security.sharedKey
			if ($key)
			{
				$keyType = $key.keyType
				$protected = $key.protected
				$material = $key.keyMaterial
			}
			else
			{
				$keyType = [String]::Empty
				$protected = [String]::Empty
				$material = [String]::Empty
			}

			$profiles += New-Object PSObject -Property @{
				SSID           = $pkg.SSIDConfig.SSID.name
				Mode           = $pkg.connectionMode
				Authentication = $pkg.MSM.Security.authEncryption.Authentication
				Encryption     = $pkg.MSM.Security.authEncryption.encryption
				KeyType        = $keyType
				Protected      = $protected
				Material       = $material
			}
		}

		(netsh wlan show interfaces | select-string ' SSID') -match '\s{2,}:\s(.*)' | Out-Null
		$active = $Matches[1].ToString()

		Write-Host "`n`nWi-Fi Profiles" -NoNewline -ForegroundColor Green
		Write-Host ", Active:$active" -NoNewline -ForegroundColor DarkGreen
		Write-Host " (netsh wlan delete profile name='NAME')" -ForegroundColor DarkGray

		$profiles | `
			Select-Object SSID, Mode, Authentication, Encryption, KeyType, Protected, Material | `
			Format-Table `
				@{ Label = 'SSID'; Expression = { MakeExpression $_ $_.SSID $active } }, `
				@{ Label = 'Mode'; Expression = { MakeExpression $_ $_.Mode $active } }, `
				@{ Label = 'Authentication'; Expression = { MakeExpression $_ $_.Authentication $active } }, `
				@{ Label = 'Encryption'; Expression = { MakeExpression $_ $_.Encryption $active } }, `
				@{ Label = 'KeyType'; Expression = { MakeExpression $_ $_.KeyType $active } }, `
				@{ Label = 'Protected'; Expression = { MakeExpression $_ $_.Protected $active } }, `
				@{ Label = 'Material'; Expression = { MakeExpression $_ $_.Material $active } } `
				-AutoSize

		Remove-Item $path -Force -Recurse -Confirm:$false
	}

	function MakeExpression
	{
		param($profile, $value, $active)
		if ($profile.SSID -eq $active) { $color = '92' }
		elseif ($profile.Encryption -eq 'none') { $color = '31' }
		elseif ($profile.Mode -eq 'manual') { $color = '90' }
		else { $color = '97' }

		"$esc[$color`m$($value)$esc[0m"
	}
}
Process
{
	if ($preferred)
	{
		return GetPreferredAddress
	}

	if ($addresses)
	{
		return GetAllAddresses
	}

	$script:verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

	$info = CollectInformation
	if ($info -and $info.Items -and $info.Items.Count -gt 0)
	{
		ShowPreferred $info.Preferred

		if ($verbose)
		{
			ShowDetailedInfo $info
		}
		else
		{
			ShowBasicInfo $info
		}
	}
	else
	{
		Write-Host 'Network unavailable' -ForegroundColor Red
	}

	if ($wiFi)
	{
		ShowWiFiProfiles
	}
}

<#
    ... This is a whole lot less code but is much slower then the code above 

$candidates = @()
Get-NetIPConfiguration | % `
{
	$dns = $_.DNSServer | ? { $_.AddressFamily -eq 2 } | select -property ServerAddresses | select -first 1
	$ifx = $_.InterfaceAlias + ', ' + $_.InterfaceDescription
	if ($_.NetProfile.Name -notmatch 'Unidentified') { $ifx += (', ' + $_.NetProfile.Name) }

	$candidates += New-Object psobject -Property @{
		Address = $_.IPv4Address.IPAddress
		DNSServer = [String]::Join(',', $dns.ServerAddresses)
		Gateway = $_.IPv4DefaultGateway.NextHop
		Interface = $ifx
	}
}
#>
