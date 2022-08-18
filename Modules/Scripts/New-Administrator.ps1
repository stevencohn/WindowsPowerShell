<#
.SYNOPSIS
Create a new local admin user.

.PARAMETER Password
The required password of the new local admin account to create.

.PARAMETER Username
The required username of the new local admin account to create.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)]

param (
	[Parameter(Mandatory=$true, Position=1)] [string] $Username,
	[Parameter(Mandatory=$true, Position=2)] [securestring] $Password
)

Begin
{
	. $PSScriptRoot\common.ps1


    function CreateAdministrator
	{
        #$Password = ConvertTo-SecureString $Password -AsPlainText -Force
        New-LocalUser $Username -Password $Password -PasswordNeverExpires -Description "Local admin"
        Add-LocalGroupMember -Group Administrators -Member $Username
	}
}
Process
{
    if (!(IsElevated))
    {
        return
    }

    if ($Username -eq $env:USERNAME)
    {
        WriteWarn '... username must be unique'
        return
    }

    $go = Read-Host 'Create local administrator? (y/n) [y]'
    if (($go -eq '') -or ($go -eq 'y'))
    {
        CreateAdministrator

        Write-Host
        $go = Read-Host "Logout to log back in as $Username`? (y/n) [y]"
        if (($go -eq '') -or ($go -eq 'y'))
        {
            logoff; exit
        }
    }
}
