<#
.SYNOPSIS
Format or pretty-pretty JSON and XML files.

.PARAMETER Path
The path to the file.

.PARAMETER Dedent
For Json, will strip unwanted extra spaces from the output, mostly.

.PARAMETER Overwrite
Overwrite the input file. Default is to print to the console.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
	[string] $Path,

	[switch] $Dedent,
	[switch] $Overwrite
)

Begin
{
	function FormatJson ($filePath)
	{
		$json = Get-Content $filePath | ConvertFrom-Json | ConvertTo-Json -Depth 100

		if ($Dedent)
		{
			# ConvertTo-Json formatting is verbose so strip unwanted spaces
			$json = ($json -split "\r\n" | % `
			{
				$line = $_
				if ($line -match '^ +')
				{
					$len = $Matches[0].Length / 4
					$line = ' ' * $len + $line.TrimStart()
				}

				$index = $line.IndexOf('":  ')
				if ($index -gt 0)
				{
					$line = $line.Replace('":  ', '": ')
				}

				$line
			}) -join [Environment]::NewLine
		}

		if ($Overwrite)
		{
			$json | Out-File -FilePath $filePath -Force
			return
		}

		$json
	}

	function FormatXml ($filePath)
	{
		$null = [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq")

		if ($Overwrite)
		{
			[Xml.Linq.XElement]::Load($filePath).Save($filePath, [Xml.Linq.SaveOptions]::None)
		}
		else
		{
			[Xml.Linq.XElement]::Load($filePath).ToString([Xml.Linq.SaveOptions]::None)
		}
	}
}
Process
{
	$filepath = Resolve-Path $Path -ErrorAction SilentlyContinue
	if (!$filepath)
	{
		Write-Host "Could not find file $Path" -ForegroundColor Yellow
		return
	}

	switch ((Get-Item $filepath).Extension)
	{
		'.json' { FormatJson $filepath }
		'.xml' { FormatXml $filepath }
		default { Write-Host 'File must have an extension of either .json or .xml' -ForegroundColor Yellow }
	}
}
