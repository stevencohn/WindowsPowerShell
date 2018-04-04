<#
.SYNOPSIS
Determines the most likely candidate for the active Internet-specific network adapter on this
machine.  All other adpaters such as tunneling and loopbacks are ignored.  Only connected IP
adapters are considered.
#>

$items = @()
if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable())
{
	[Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | % `
	{
        if ($_.NetworkInterfaceType -ne 'Loopback')
        {
		    $item = New-Object PSObject -Property @{
			    Address = $null
			    DNSServer = $null
			    Gateway = $null
			    Description = $null
                HasStats = $false
                Status = $_.OperationalStatus
                Type = $_.NetworkInterfaceType
            }

            $props = $_.GetIPProperties()

            if (($props.UnicastAddresses.Count -gt 0) -and `
                ($props.UnicastAddresses[0].Address.AddressFamily -eq 'InterNetwork'))
            {
                $item.Address = $props.UnicastAddresses[0].Address.IPAddressToString
            }

            if (($props.DnsAddresses.Count -gt 0) -and `
                ($props.DnsAddresses[0].AddressFamily -eq 'InterNetwork'))
            {
                $item.DNSServer = $props.DnsAddresses[0].IPAddressToString
            }

	        if (($props.GatewayAddresses.Count -gt 0) -and `
                ($props.GatewayAddresses[0].Address.AddressFamily -eq 'InterNetwork'))
            {
                $item.Gateway = $props.GatewayAddresses[0].Address.IPAddressToString
		    }

            $stats = $_.GetIPv4Statistics() | Select -first 1
            $item.HasStats = ($stats.BytesReceived -gt 0) -and ($stats.BytesSent -gt 0)

            $item.Description = $_.Name + ', ' + $_.Description
            if (($props.DnsSuffix -ne $null) -and ($props.DnsSuffix.Length -gt 0))
            {
                $item.Description += (', ' + $props.DnsSuffix)
            }

            $items += $item
        }
	}

    $preferred = $items | ? { $_.HasStats -and $_.Address -and $_.DnsAddress -and $_.Gateway } | select -first 1 -ExpandProperty Address
    if ($preferred -eq $null)
    {
        $preferred = $items | ? { $_.HasStats -and $_.Address } | select -first 1 -ExpandProperty Address
    }

    Write-Host
    if ($preferred -eq $null)
    {
        Write-Host 'Preferred address is unknown' -ForegroundColor DarkGreen
    }
    else
    {
        Write-Host ("Preferred address is {0}" -f $preferred) -ForegroundColor Green
    }

    Write-Host
    Write-Host 'Address         DNS Server      Gateway         Interface'
    Write-Host '-------         ----------      -------         ---------'
    $items | % `
    {
	    $line = ("{0,-15} {1,-15} {2,-15} {3}" -f $_.Address, $_.DNSServer, $_.Gateway, $_.Description)
        if ($_.Status -eq 'Down') {
            Write-Host $line -ForegroundColor DarkGray
        }
	    elseif ($_.Address -eq $preferred.Address) {
		    Write-Host $line -ForegroundColor Green
	    }
	    elseif ($_.Description -match 'Wi-Fi') {
		    Write-Host $line -ForegroundColor Cyan
	    }
	    elseif ($_.Description -match 'Bluetooth') {
		    Write-Host $line -ForegroundColor DarkCyan
	    }
	    else {
		    Write-Host $line
	    }
    }
}
else
{
    Write-Host 'Network unavailable' -ForegroundColor Red
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
