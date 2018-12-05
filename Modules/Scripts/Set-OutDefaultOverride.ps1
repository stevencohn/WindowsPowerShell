
New-CommandWrapper Out-Default -Process {
	$nocase = ([Text.RegularExpressions.RegexOptions]::IgnoreCase)
	$compressed = New-Object Text.RegularExpressions.Regex('\.(zip|tar|gz|iso)$', $nocase)
	$executable = New-Object Text.RegularExpressions.Regex('\.(exe|bat|cmd|msi|ps1|psm1)$', $nocase)

	if (($_ -is [IO.DirectoryInfo]) -or ($_ -is [IO.FileInfo])) {
		if (-not ($notfirst)) {
			$parent = [IO.Path]::GetDirectoryName($_.FullName)
			Write-Host "`n    Directory: $parent`n"
			Write-Host 'Mode        Last Write Time       Length   Name'
			Write-Host '----        ---------------       ------   ----'
			$notfirst = $true
		}

		if ($_ -is [IO.DirectoryInfo]) {
			Write-Host ('{0} {1,12} {2,8} {3,14}' -f $_.mode, $_.LastWriteTime.ToString('d'), $_.LastWriteTime.ToString('t'), '') -NoNewline
			if ($_.LinkType) {
				Write-Host $_.name -ForegroundColor Blue -NoNewline
				$target = ($_ | select -expand Target).Replace('UNC\','\\')
				Write-Host " -> $target" -ForegroundColor DarkBlue
			}
			else { Write-Host $_.name -ForegroundColor Blue }
		}
		else {
			if ($compressed.IsMatch($_.Name)) { $color = 'Magenta' }
			elseif ($executable.IsMatch($_.Name)) { $color = 'DarkGreen' }
			else { $color = 'Gray' }

			Write-Host ('{0} {1,12} {2,8} {3,12}  ' -f $_.mode, $_.LastWriteTime.ToString('d'), $_.LastWriteTime.ToString('t'), $_.length) -NoNewline
			Write-Host $_.name -ForegroundColor $color
		}

		$_ = $null
	}
} -end {
	Write-Host
}