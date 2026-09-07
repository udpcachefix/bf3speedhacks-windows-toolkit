#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Excluded', 'Included')]
    [string]$State
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$valueName = 'ExcludeWUDriversInQualityUpdate'

if ($State -eq 'Excluded') {
    if ($PSCmdlet.ShouldProcess($policyPath, 'Exclude drivers from Windows quality updates')) {
        if (-not (Test-Path -LiteralPath $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }

        New-ItemProperty -Path $policyPath -Name $valueName -PropertyType DWord -Value 1 -Force | Out-Null
        Write-Host 'Drivers are now excluded from Windows quality updates by local policy.'
    }
}
else {
    if ($PSCmdlet.ShouldProcess($policyPath, 'Remove the local driver-exclusion policy')) {
        if (Get-ItemProperty -Path $policyPath -Name $valueName -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $policyPath -Name $valueName
        }

        Write-Host 'The local driver-exclusion policy is not configured. Effective domain or MDM policy may still apply.'
    }
}
