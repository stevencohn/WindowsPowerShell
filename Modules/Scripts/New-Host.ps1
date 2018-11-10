<#
.SYNOPSIS
Adds or updates an entry in the Windows hosts file

.PARAMETER IP
The IP address to associate with the host name.
If IP is an empty string then delete Name entries.
.PARAMETER Name
The host name to associate with the IP address.
If Name is an empty string then delete IP entries.
#>

param (
	[Parameter(Position=0,ValueFromPipeline=$true)]
	[ValidateScript({$_ -match [IPAddress]$_ })]  
	[string] $IP,

	[Parameter(Position=1,ValueFromPipeline=$true)]
	[string] $Name
)

if ($IP -and $Name) { $pattern = ("(^{0}\b)|(\b{1}\b)" -f $IP.Trim(), $Name.Trim()) }
elseif ($IP) { $pattern = ("(^{0}\b)" -f $IP.Trim()) }
elseif ($Name) { $pattern = ("(\b{0}\b)" -f $Name.Trim()) }

$lines = @()
$file = "$env:windir\System32\drivers\etc\hosts"
if (Test-Path $file)
{
	$lines = Get-Content $file | ? { $_ -notmatch $pattern }
}

# if either is empty then don't add (delete)
if ((-not [String]::IsNullOrEmpty($IP)) -and (-not [String]::IsNullOrEmpty($Name)))
{
	$lines += "$IP $Name"
}

$lines | Out-File -FilePath $file -Force -Encoding utf8 -Confirm:$false
