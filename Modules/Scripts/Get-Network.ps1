<#
.SYNOPSIS
Determines the most likely candidate for the active Internet-specific network adapter on this
machine.  All other adpaters such as tunneling and loopbacks are ignored.  Only connected IP
adapters are considered.
#>

$address = $null

# only recognizes changes related to Internet adapters
if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
{	
	# filter all adapters so we see only Internet adapters
	[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() `
		| ? { ($_.OperationalStatus -eq [Net.NetworkInformation.OperationalStatus]::Up) -and `
		($_.NetworkInterfaceType -ne [Net.NetworkInformation.NetworkInterfaceType]::Tunnel ) -and `
		($_.NetworkInterfaceType -ne [Net.NetworkInformation.NetworkInterfaceType]::Loopback ) } `
		| % `
 	{
		# At one point, I had the following pipe filter as the last part of the filter just
		# entering this block of code, not sure why though: | select -first 10 

		$face = $_

		# all testing seems to prove that once an interface comes online
		# it has already accrued statistics for both received and sent...

		$face.GetIPv4Statistics() | ? { ($_.BytesReceived -gt 0) -and ($_.BytesSent -gt 0) } | % `
		{
			# the unicast address tells us our actual IP, both v4 and v6
			$face.GetIPProperties() | ? { $_.UnicastAddresses.Count -gt 0 } | select -first 1 | % `
			{
				# select the v4-specific address
				$_.UnicastAddresses `
					| ? { $_.Address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork } `
					| select -first 1 | % `
				{
					$address = $_.Address.IPAddressToString
				}
			}
		}
	}
}

Write-Host
Write-Host "Preferred address is $address" -ForegroundColor Green

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

Write-Host
Write-Host 'Address         DNS Server      Gateway         Interface'
Write-Host '-------         ----------      -------         ---------'
$candidates | % `
{
	$line = ("{0,-15} {1,-15} {2,-15} {3}" -f $_.Address, $_.DNSServer, $_.Gateway, $_.Interface)
	if ($_.Address -eq $address) {
		Write-Host $line -ForegroundColor Green
	}
	elseif ($_.Interface -match 'Wi-Fi') {
		Write-Host $line -ForegroundColor Cyan
	}
	elseif ($_.Interface -match 'Bluetooth') {
		Write-Host $line -ForegroundColor DarkCyan
	}
	else {
		Write-Host $line
	}
}
