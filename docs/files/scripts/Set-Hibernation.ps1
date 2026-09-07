#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Enabled', 'Disabled')]
    [string]$State
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$argument = if ($State -eq 'Enabled') { 'on' } else { 'off' }
$description = if ($State -eq 'Enabled') {
    'Enable hibernation and make Fast Startup available'
}
else {
    'Disable hibernation and Fast Startup and remove hiberfil.sys'
}

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $description)) {
    $process = Start-Process -FilePath "$env:SystemRoot\System32\powercfg.exe" `
        -ArgumentList '/hibernate', $argument `
        -Wait `
        -PassThru `
        -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "powercfg.exe failed with exit code $($process.ExitCode)."
    }

    Write-Host "Hibernation is now $($State.ToLowerInvariant())."
}
