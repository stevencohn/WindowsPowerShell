<#
.SYNOPSIS
Sets AWS keys in the .aws/config file

.PARAMETER AccessKey
Optional, sets the AWS access key in configuration 

.PARAMETER SecretKey
Optional, sets the AWS secret key in configuration
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
	[Parameter(Mandatory = $true)] [string] $AccessKey,
	[Parameter(Mandatory = $true)] [string] $SecretKey
)

Begin
{
	function TestAwsConfiguration
	{
		$ok = (Test-Path $home\.aws\config) -and (Test-Path $home\.aws\credentials)

		if (!$ok)
		{
			Write-Host
			Write-Host '... AWS credentials are required' -ForegroundColor Yellow
			Write-Host '... Specify the -AccessKey and -SecretKey parameters' -ForegroundColor Yellow
		}

		return $ok
	}


	function ConfigureAws
	{
		param($access, $secret)

		if (!(Test-Path $home\.aws))
		{
			New-Item $home\.aws -ItemType Directory -Force -Confirm:$false | Out-Null
		}

		'[default]', `
			'region = us-east-1', `
			'output = json' `
			| Out-File $home\.aws\config -Encoding ascii -Force -Confirm:$false

		'[default]', `
			"aws_access_key_id = $access", `
			"aws_secret_access_key = $secret" `
			| Out-File $home\.aws\credentials -Encoding ascii -Force -Confirm:$false

		Write-Verbose 'AWS configured; no need to specify access/secret keys from now on'
	}
}
Process
{
    # harmless to do this even before AWS is installed
    ConfigureAws $AccessKey $SecretKey
}
