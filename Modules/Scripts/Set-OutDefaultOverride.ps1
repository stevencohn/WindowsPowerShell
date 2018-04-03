
New-CommandWrapper Out-Default -Process {
	$nocase = ([Text.RegularExpressions.RegexOptions]::IgnoreCase)
	$compressed = New-Object Text.RegularExpressions.Regex('\.(zip|tar|gz|iso)$', $nocase)
	$executable = New-Object Text.RegularExpressions.Regex('\.(exe|bat|cmd|msi|ps1|psm1)$', $nocase)

	if (($_ -is [IO.DirectoryInfo]) -or ($_ -is [IO.FileInfo])) {
		if (-not ($notfirst)) {
			$parent = [IO.Path]::GetDirectoryName($_.FullName)
			Write-Host "`n    Directory: $parent`n"
			Write-Host "Mode        Last Write Time       Length   Name"
			Write-Host "----        ---------------       ------   ----"
			$notfirst = $true
		}

		if ($_ -is [IO.DirectoryInfo]) {
			Write-Host ("{0}   {1}               " -f $_.mode, ([String]::Format("{0,10} {1,8}", $_.LastWriteTime.ToString("d"), $_.LastWriteTime.ToString("t")))) -NoNewline
			Write-Host $_.name -ForegroundColor "Blue"
		}
		else {
			if ($compressed.IsMatch($_.Name)) {
				$color = "Magenta"
			}
			elseif ($executable.IsMatch($_.Name)) {
				$color = "DarkGreen"
			}
			else {
				$color = "Gray"
			}
			Write-Host ("{0}   {1}   {2,10}  " -f $_.mode, ([String]::Format("{0,10} {1,8}", $_.LastWriteTime.ToString("d"), $_.LastWriteTime.ToString("t"))), $_.length) -NoNewline
			Write-Host $_.name -ForegroundColor $color
		}

		$_ = $null
	}
} -end {
	Write-Host
}