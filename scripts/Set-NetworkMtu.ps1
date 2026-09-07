#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$InterfaceAlias,

    [Parameter(Mandatory)]
    [ValidateRange(576, 9000)]
    [int]$MtuBytes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$interfaces = @(Get-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction Stop)
if ($interfaces.Count -ne 1) {
    throw "Expected one IPv4 interface named '$InterfaceAlias', found $($interfaces.Count). Use Get-NetIPInterface -AddressFamily IPv4 to select an exact alias."
}

$interface = $interfaces[0]
$previousMtu = $interface.NlMtu

if ($previousMtu -eq $MtuBytes) {
    Write-Host "Interface '$InterfaceAlias' already uses MTU $MtuBytes."
    return
}

if ($PSCmdlet.ShouldProcess($InterfaceAlias, "Change IPv4 MTU from $previousMtu to $MtuBytes")) {
    Set-NetIPInterface -InterfaceIndex $interface.InterfaceIndex -AddressFamily IPv4 -NlMtuBytes $MtuBytes

    Get-NetIPInterface -InterfaceIndex $interface.InterfaceIndex -AddressFamily IPv4 |
        Select-Object InterfaceAlias, InterfaceIndex, AddressFamily, NlMtu
}
