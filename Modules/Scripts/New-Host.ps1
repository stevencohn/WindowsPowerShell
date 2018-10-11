<#
.SYNOPSIS
Adds or updates an entry in the Windows hosts file

.PARAMETER IP
The IP address to associate with the host name.
.PARAMETER Name
The host name to associate with the IP address.
#>

param (
	[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
	[ValidateScript({$_ -match [IPAddress]$_ })]  
	[string] $IP,

	[Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)]
	[string] $Name
)

$file = "$env:windir\System32\drivers\etc\hosts"
$lines = Get-Content $file | ? { $_ -notmatch "(^$IP\b)|(\b$Name\b)" }
$lines += "$IP $Name"
$lines | Out-File -FilePath $file -Force -Encoding utf8 -Confirm:$false
