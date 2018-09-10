<#
.SYNOPSIS
Enable PowerShell remoting and trusted hosts for the current machine,
typically run on a VM that will be used for automated tasks such as CI/CD.

.DESCRIPTION
Should be done along with enabling Hyper-V Guest Integration Services with:
Enable-VMIntegrationService -Name 'Guest Service Interface' -VMName 'win10'
#>

param()

# SkipNetworkProfileCheck if VM network profile is set to Public
# Alternative is to change network profile using:
# Set-NetConnectionProfile -NetworkCategory Private
# Other categories are Domain and Public

# use Production (stateless) or Standard (state)
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Service WinRM -StartMode Automatic

# set connect profile type to Private (required for AllowUnencrypted)
Set-NetConnectionProfile -NetworkCategory Private

# open up WinRM service (see full config with 'winrm get winrm/config')
winrm quickconfig -q
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# allow all remote hosts
Set-Item -Force wsman:\localhost\client\trustedhosts *

# open firewall for WinRM clients (or disable firewall)
netsh firewall add portopening TCP 5985 "Port 5985"
