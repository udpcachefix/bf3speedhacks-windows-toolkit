#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Description = 'Windows configuration checkpoint'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command -Name Checkpoint-Computer -ErrorAction SilentlyContinue)) {
    throw 'Checkpoint-Computer is unavailable. It requires a supported Windows client edition.'
}

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Create restore point '$Description'")) {
    try {
        Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS
        Write-Host "Restore point requested successfully: $Description"
    }
    catch {
        throw "Restore point creation failed: $($_.Exception.Message)"
    }
}
