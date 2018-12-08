
New-CommandWrapper Out-Default -Process {
	$nocase = [Text.RegularExpressions.RegexOptions]::IgnoreCase
	$compressed = New-Object Text.RegularExpressions.Regex('\.(zip|tar|gz|iso)$', $nocase)
	$executable = New-Object Text.RegularExpressions.Regex('\.(exe|bat|cmd|msi|ps1|psm1)$', $nocase)

	if (($_ -is [IO.DirectoryInfo]) -or ($_ -is [IO.FileInfo])) {

		# This function is run in a new scope for each Get-ChildItem call and that scope
		# is reused until that invokation is complete which means we can take advantage
		# of that scope to "cache" our own information like $junctions
		if (-not $notfirst) {
			$parent = [IO.Path]::GetDirectoryName($_.FullName)
			Write-Host "`n    Directory: $parent`n"
			Write-Host 'Mode      Last Write Time       Length   Name'
			Write-Host '----      ---------------       ------   ----'
			$notfirst = $true
			$junctions = cmd /c "dir /al $parent" | ? { $_ -match '<JUNCTION>' }
		}

		$name = $_.Name
		if ($_ -is [IO.DirectoryInfo]) {
			Write-Host ('{0} {1,11} {2,8}' -f $_.mode, $_.LastWriteTime.ToString('d'), $_.LastWriteTime.ToString('t')) -NoNewline
			if ($_.LinkType) {
				Write-Host ('{0,12}  ' -f 'symlink') -ForegroundColor DarkGray -NoNewline
				Write-Host $name -ForegroundColor Blue -NoNewline
				$target = ($_ | select -expand Target).Replace('UNC\','\\')
				Write-Host " > $target" -ForegroundColor DarkBlue
			}
			elseif ($_.Attributes -match 'ReparsePoint')
			{
				Write-Host ('{0,12}  ' -f 'junction') -ForegroundColor DarkGray -NoNewline
				if (($junctions | ? { $_ -match "$name \[" }) -match '\[([^\]]+)\]$')
				{
					Write-Host $name -ForegroundColor Blue -NoNewline
					Write-Host " > $($matches[1])" -ForegroundColor DarkBlue
				}
				else { Write-Host $name -ForegroundColor Blue }
			}
			else
			{
				Write-Host ('{0,12}  ' -f '') -NoNewline
				Write-Host $name -ForegroundColor Blue
			}
		}
		else {
			if ($compressed.IsMatch($name)) { $color = 'Magenta' }
			elseif ($executable.IsMatch($name)) { $color = 'DarkGreen' }
			else { $color = 'Gray' }

			# ensure size fits within the 11 char column
			$size = $_.Length
			if ($size -gt 90GB) { $size = ('{0} GB' -f ($size / 1GB).ToString('0.###')) }

			Write-Host ('{0} {1,11} {2,8} {3,11}  ' -f $_.mode, $_.LastWriteTime.ToString('d'), $_.LastWriteTime.ToString('t'), $size) -NoNewline
			Write-Host $name -ForegroundColor $color
		}

		$_ = $null
	}
} -end {
	Write-Host
}