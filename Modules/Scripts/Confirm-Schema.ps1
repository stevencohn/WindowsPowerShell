<#
.SYNOPSIS
Validates an XML file against a given schema definition file.

.PARAMETER XmlPath
Path of the XML file to validate.

.PARAMETER XsdPath
Path of the XSD schema definnition file used to validate the XML file.

.PARAMETER Namespace
The namespace to add to the validation.
#>

# CmdletBinding adds -Verbose functionality, SupportsShouldProcess adds -WhatIf
[CmdletBinding(SupportsShouldProcess = $true)]

[OutputType([bool])]

param
(
	[Parameter(Mandatory)]
	[ValidateScript({ Test-Path -Path $_ })]
	[ValidatePattern('\.xml')]
	[string] $XmlPath,

	[Parameter(Mandatory)]
	[ValidateScript({ Test-Path -Path $_ })]
	[ValidatePattern('\.xsd')]
	[string] $XsdPath,
	
	[string] $Namespace = 'http://schemas.microsoft.com/office/onenote/2013/onenote'
)
Begin
{
	<#
	<?xml version="1.0"?>
	<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"
				targetNamespace="http://schemas.microsoft.com/office/onenote/2013/onenote"
				xmlns="http://schemas.microsoft.com/office/onenote/2013/onenote"
				elementFormDefault="qualified">
	#>
}
Process
{
    try
    {
        [xml]$xml = Get-Content $XmlPath
        $xml.Schemas.Add($Namespace, $XsdPath) | Out-Null
        $xml.Validate($null)
        Write-Verbose "Successfully validated $XmlPath against schema ($XsdPath)"
        $result = $true
    }
    catch
    {
        $err = $_.Exception.Message
        Write-Verbose "Failed to validate $XmlPath against schema ($XsdPath)`nDetails: $err"
		$_
        $result = $false
    }
    finally
    {
        $result
    }
}
