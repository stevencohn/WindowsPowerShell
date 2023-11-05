<#
.SYNOPSIS
Sign in to AWS CLI using MFA for the configured profile of an IAM user.

.PARAMETER Account
Your AWS account number, default is $env:AWS_ACCOUNT.

.PARAMETER Code
The current code from your MFA device, e.g. Microsoft Authenticator

.PARAMETER Device
The name of your IAM MFA profile, default is $env:AWS_PROFILE.
This can be found under your IAM user, security credentials tab, in the MFA section;
it is the last part of the device identifier arn.
It should alos be visible in your MFA app, the part before the '@'

.PARAMETER Profile
Your configured AWS profile name, default is $env:AWS_PROFILE.

.DESCRIPTION
This requires only a simple profile in your .aws/config such as

[profile my-profile-name]
region = us-east-1
output = json
#>

param(
	[string] $Account,
	[string] $Device,
	[string] $Profile,
	[string] $Code
)

Begin
{
	function Login
	{
		$json = (aws sts get-session-token `
			--serial-number arn:aws:iam::$Account`:mfa/$Device `
			--token-code $Code --profile $Profile)

		if ($LASTEXITCODE -ne 0)
		{
			Write-Host 'Error getting session' -ForegroundColor Red
			Write-Host $json
			return
		}

		$credentials = ($json | ConvertFrom-Json).Credentials

		$env:AWS_ACCESS_KEY_ID = $credentials.AccessKeyId
		$env:AWS_SECRET_ACCESS_KEY = $credentials.SecretAccessKey
		$env:AWS_SESSION_TOKEN = $credentials.SessionToken

		$delta = [DateTime]::Parse($credentials.Expiration) - [DateTime]::Now
		Write-Host
		Write-Host "Successfully connected, session expires in $($delta.Hours)h $($delta.Minutes)m" -ForegroundColor Green
	}
}
Process
{
	if (!$Account)
	{
		$Account = Read-Host -Prompt "... AWS account # [$env:AWS_ACCOUNT]"
		if ([String]::IsNullOrWhiteSpace($Account)) { $Account = $env:AWS_ACCOUNT }
		if ([String]::IsNullOrWhiteSpace($Account)) { exit 0 }
	}

	if (!$Profile)
	{
		$Profile = Read-Host -Prompt "... AWS profile [$env:AWS_PROFILE]"
		if ([String]::IsNullOrWhiteSpace($Profile)) { $Profile = $env:AWS_PROFILE }
		if ([String]::IsNullOrWhiteSpace($Profile)) { exit 0 }
	}

	if (!$Device)
	{
		$Device = Read-Host -Prompt "... MFA device [$env:AWS_DEVICE]"
		if ([String]::IsNullOrWhiteSpace($Device)) { $Device = $env:AWS_DEVICE }
		if ([String]::IsNullOrWhiteSpace($Device)) { exit 0 }
	}

	if (!$Code)
	{
		$Code = Read-Host -Prompt '... MFA code'
		if ([String]::IsNullOrWhiteSpace($Code)) { exit 0 }
	}

	Login
}
