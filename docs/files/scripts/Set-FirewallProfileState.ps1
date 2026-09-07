#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Enabled', 'Disabled')]
    [string]$State,

    [Parameter()]
    [ValidateSet('All', 'Domain', 'Private', 'Public')]
    [string]$Profile = 'All',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($State -eq 'Disabled' -and -not $Force) {
    throw 'Disabling a firewall profile requires -Force. Prefer a narrow firewall rule instead.'
}

$profiles = if ($Profile -eq 'All') { @('Domain', 'Private', 'Public') } else { @($Profile) }
$enabledValue = if ($State -eq 'Enabled') { 'True' } else { 'False' }
$target = $profiles -join ', '

if ($PSCmdlet.ShouldProcess($target, "Set Windows Firewall profiles to $State")) {
    Set-NetFirewallProfile -Profile $profiles -Enabled $enabledValue
    Get-NetFirewallProfile -Profile $profiles |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
}
