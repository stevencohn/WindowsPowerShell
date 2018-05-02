<#
.SYNOPSIS
Display the /etc/hosts file
#>

$addresses = (Get-Network -addresses)

$file = "$env:windir\System32\drivers\etc\hosts"
Get-Content $file | % `
{
	$i = $_.IndexOf('#')
	if ($i -eq 0)
	{
		Write-Host $_ -ForegroundColor DarkGreen
	}
	elseif ($i -gt 0)
	{
		$left = $_.Substring(0, $i - 1)
		$addr = $_.Split(' ')
		if ($addr.Length -gt 0)
		{
			if ($addresses.Contains($addr[0]))
			{
				Write-Host $left -NoNewline -ForegroundColor White
			}
			else
			{
				Write-Host $left -NoNewline -ForegroundColor DarkGray
			}
		}
		else
		{
			Write-Host $left -NoNewline
		}

		Write-Host ("`t" + $_.Substring($i)) -ForegroundColor DarkCyan
	}
	else
	{
		Write-Host $_
	}
}
