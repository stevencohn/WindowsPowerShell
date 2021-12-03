<#
.SYNOPSIS
Determines the most likely candidate for the active Internet-specific network adapter on this
machine.  All other adpaters such as tunneling and loopbacks are ignored.  Only connected IP
adapters are considered.

.PARAMETER Preferred
Only return the preferred network address without report bells and whistles

.PARAMETER Addresses
Return a @(list) of addresses

.PARAMETER Verbose
Display extra information including MAC addres and bytes sent/received.
#>

using namespace System.Net
using namespace System.Net.NetworkInformation

[CmdletBinding()]

param(
	[switch] $preferred,	# just return the preferred address
	[switch] $addresses		# return a list of host addresses
)

Begin
{
	function Get-Addresses ()
	{
		$addresses = @()
		if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
		{
			[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | % `
			{
				$props = $_.GetIPProperties()

				$address = $props.UnicastAddresses `
					| ? { $_.Address.AddressFamily -eq 'InterNetwork' } `
					| select -first 1 -ExpandProperty Address

				if ($address)
				{
					$addresses += $address.IPAddressToString
				}
			}
		}

		$addresses
	}

	function Get-Preferred ()
	{
		$prefs = @()
		if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
		{
			[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | % `
			{
				if (($_.NetworkInterfaceType -ne 'Loopback') -and ($_.OperationalStatus -eq 'Up'))
				{
					$props = $_.GetIPProperties()
 
					$address = $props.UnicastAddresses `
						| ? { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty Address

					$DNSServer = $props.DnsAddresses `
						| ? { $_.AddressFamily -eq 'InterNetwork' } `
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

	function Get-Information ()
	{
		$preferred = $null
		$items = @()
		if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
		{
			[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | % `
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
						BytesReceived   = 0
						BytesSent       = 0
						Status          = $_.OperationalStatus
						Type            = $_.NetworkInterfaceType
					}
			
					$props = $_.GetIPProperties()

					$item.Address = $props.UnicastAddresses `
						| ? { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty Address

					$item.DNSServer = $props.DnsAddresses `
						| ? { $_.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty IPAddressToString

					$item.Gateway = $props.GatewayAddresses `
						| ? { $_.Address.AddressFamily -eq 'InterNetwork' } `
						| select -first 1 -ExpandProperty Address

					if ($verbose)
					{
						$stats = $_.GetIPv4Statistics() | Select -first 1
						$item.BytesReceived = $stats.BytesReceived
						$item.BytesSent = $stats.BytesSent
					}

					$item.Description = $_.Name + ', ' + $_.Description
					$item.DnsSuffix = $props.DnsSuffix
					if (($props.DnsSuffix -ne $null) -and ($props.DnsSuffix.Length -gt 0))
					{
						if ($item.Type.ToString().StartsWith('Wireless'))
						{
							$ssid = netsh wlan show interfaces | Select-String '\sSSID'
							if ($ssid)
							{
								$profile = $ssid.ToString().Split(':')[1].Trim()
								if ($profile) { $item.Description += (', ' + $profile) }
							}
						}
						else
						{
							$item.Description += (', ' + $props.DnsSuffix)
						}
					}

					if ((!$preferred) -and ($item.Status -eq 'Up') -and $item.Address -and $item.DNSServer)
					{
						$preferred = $item.Address
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

	function Show-Preferred ($preferred)
	{
		Write-Host
		if ($preferred -eq $null)
		{
			Write-Host ('{0} Preferred address is unknown' -f $env:COMPUTERNAME) -ForegroundColor DarkGreen -NoNewline
		}
		else
		{
			Write-Host ("{0} Preferred address is {1}" -f $env:COMPUTERNAME, $preferred) -ForegroundColor Green -NoNewline
		}

		# make FQDN
		$domain = [IPGlobalProperties]::GetIPGlobalProperties().DomainName
		if ([String]::IsNullOrEmpty($domain)) { $domain = [Dns]::GetHostName() }
		$name = [Dns]::GetHostName()
		if ($name -ne $domain) { $name = $name + '.' + $domain }
		Write-Host " ($name)" -ForegroundColor DarkGreen
	}

	function Get-ForeColor ($item, $preferred)
	{
		if ($item.Status -ne 'Up') { @{ foregroundcolor='DarkGray' } }
		elseif ($item.Address -eq $preferred) { @{ foregroundcolor='Green' } }
		elseif ($item.Type -match 'Wireless') { @{ foregroundcolor='Cyan' } }
		elseif ($item.Description -match 'Bluetooth') { @{ foregroundcolor='DarkCyan' } }
		else { @{ } }
	}

	function Show-Information ($info)
	{
		Write-Host
		Write-Host 'Address         DNS Server      Gateway         Interface'
		Write-Host '-------         ----------      -------         ---------'
		$info.Items | % `
		{
			$line = ("{0,-15} {1,-15} {2,-15} {3}" -f $_.Address, $_.DNSServer, $_.Gateway, $_.Description)
			$hash = Get-ForeColor $_ $info.Preferred
			Write-Host $line @hash
		}
	}

	function Show-Verbose ($info)
	{
		Write-Host
		Write-Host 'IP/DNS/Gateway   Interface Details'
		Write-Host '--------------   -----------------'
		$info.Items | % `
		{
			for ($i = 10; $i -gt 0; $i -= 2) { $_.PhysicalAddress = $_.PhysicalAddress.insert($i, '-') }
			$hash = Get-ForeColor $_ $info.Preferred

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
}
Process
{
	if ($preferred)
	{
		return Get-Preferred
	}

	if ($addresses)
	{
		return Get-Addresses
	}

	$script:verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

	$info = Get-Information
	if ($info -and $info.Items -and $info.Items.Count -gt 0)
	{
		Show-Preferred $info.Preferred

		if ($verbose)
		{
			Show-Verbose $info
		}
		else
		{
			Show-Information $info
		}
	}
	else
	{
		Write-Host 'Network unavailable' -ForegroundColor Red
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
