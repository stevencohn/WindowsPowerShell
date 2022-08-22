<#
.SYNOPSIS
Get the version of.NET Framework installations on the local computer

.DESCRIPTION
Note that when new versions are released then the lookup table needs to be updated.

https://support.microsoft.com/en-us/help/318785/how-to-determine-which-versions-and-service-pack-levels-of-the-microso
#>

$netrun = '-'
$netsdk = '-'

if ((Get-Command dotnet -ErrorAction:SilentlyContinue) -ne $null)
{
	$m = (dotnet --list-runtimes) | where { $_ -match '\.NETCore' } | select -last 1 | select-string -pattern '^(.*) \['
	if ($m.Matches.Success) { $netrun = $m.Matches.Groups[1].Value}

	$m = (dotnet --list-sdks) | select -last 1 | select-string -pattern '^(.*) \['
	if ($m.Matches.Success) { $netsdk = $m.Matches.Groups[1].Value}
}

Write-Host
Write-Host ".NET Runtime: $netrun"
Write-Host ".NET SDK....: $netsdk"
Write-Host

Write-Host "Framework...: $([Environment]::Version)" -NoNewline

Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
Get-ItemProperty -name Version,Release,Install,PSChildName,SP -EA 0 |
Where { $_.PSChildName -match '^(?!S)\p{L}'} |
Select PSChildName, Version, Release, @{
	name='Product'
	expression={
		if ($_.Release -ge 528449) { '4.8 Windows 11 or Windows Server 2022' }
		elseif ($_.Release -ge 528372) { '4.8 Windows 10 May 2020, Oct 2020, May 2021' }
		elseif ($_.Release -ge 528040) { '4.8 Windows 10 May 2019, Nov 2019' }
		elseif ($_.Release -ge 461808) { '4.7.2' }
		elseif ($_.Release -ge 461308) { '4.7.1' }
		elseif ($_.Release -ge 460798) { '4.7 Original Release' }
		elseif ($_.Release -eq 394802) { '4.6.2 Windows 10 Anniverary Update' }
		elseif ($_.Release -eq 394806) { '4.6.2' }
		elseif ($_.Release -eq 394254) { '4.6.1 Windows 10 November Update' }
		elseif ($_.Release -ge 394271) { '4.6.1' }
		elseif ($_.Release -ge 393295) { '4.6 Windows 10' }
		elseif ($_.Release -ge 379897) { '4.6 Original Release' }
		elseif ($_.Release -ge 379893) { '4.5.2' }
		elseif ($_.Release -ge 378675) { '4.5.1 Windows 8.1 or Windows Server 2012' }
		elseif ($_.Release -ge 378758) { '4.5.1 Windows 8, Windows 7 SP1, or Windows Vista SP2' }
		elseif ($_.Release -ge 378389) { '4.5 Original Release' }
		elseif ($_.PSChildName -eq 'v3.5' -and $_.SP -eq 1) { '3.5 ServicePack 1' }
		elseif ($_.PSChildName -eq 'v3.5') { '3.5 Original Release' }
		elseif ($_.PSChildName -eq 'v3.0' -and $_.SP -eq 2) { '3.5 ServicePack 2' }
		elseif ($_.PSChildName -eq 'v3.0' -and $_.SP -eq 1) { '3.5 ServicePack 1' }
		elseif ($_.PSChildName -eq 'v3.0') { '3.5' }
		elseif ($_.PSChildName -match 'v2.0' -and $_.SP -eq 2) { '2.0 ServicePack 2' }
		elseif ($_.PSChildName -match 'v2.0' -and $_.SP -eq 1) { '2.0 ServicePack 1' }
		elseif ($_.PSChildName -match 'v2.0') { '3.5' }
		else { '' }
	}
}
