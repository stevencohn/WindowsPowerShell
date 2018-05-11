<#
Sign the current file using the first code signing certificatein the machine root repo.
Must be run in the PowerShell ISE.
#>

function Write-Signature ()
{
	Set-StrictMode -Version Latest

    $file = $psISE.CurrentFile
    $row = $file.Editor.CaretLine
    $col = $file.Editor.CaretColumn

    # make writable
    if (!$file.IsUntitled)
    {
        if ($file.FullPath -and (Test-Path $file.FullPath))
        {
            Set-ItemProperty $file.FullPath -name IsReadOnly -value $false
        }
    }

	# get the certificate
	$cert = Get-ChildItem -Path Cert:\LocalMachine\Root -CodeSigningCert
	if ($cert)
	{
		# save the file if necessary
		if (!$psISE.CurrentFile.IsSaved)
		{
			$psISE.CurrentFile.Save()
		}

		# if the file is encoded as BigEndian, resave as Unicode
		if ($psISE.CurrentFile.Encoding.EncodingName -match "Big-Endian")
		{
			$psISE.CurrentFile.Save([Text.Encoding]::Unicode) | Out-Null
		}

		# save the filepath for the current file so it can be re-opened later
		$filepath = $psISE.CurrentFile.FullPath

		# sign the file
		try
        {
            $cert = $cert | Select -first 1
		    Set-AuthenticodeSignature -FilePath $filepath -Certificate $cert -errorAction Stop | Out-Null

            $files = $psISE.CurrentPowerShellTab.Files
		    # close the file
		    $files.Remove($psISE.currentfile) | Out-Null

		    # reopen the file
		    $files.Add($filepath) | out-null
            $file = $files.Item($files.Count - 1)
            $files.SetSelectedFile($file)
            $file.Editor.SetCaretPosition($row, $col)
		}
		catch
        {
		    Write-Warning ("Script signing failed. {0}" -f $_.Exception.message)
		}
	}
	else
	{
		Write-Warning "No code signing certificate found."
	}
}
