#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Current', 'Remove')]
    [string]$Mode,

    [Parameter()]
    [switch]$RestartUpdateService
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$currentVersionPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

if ($Mode -eq 'Current') {
    $current = Get-ItemProperty -Path $currentVersionPath
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
    if ([int]$operatingSystem.BuildNumber -lt 22000) {
        throw "This repository procedure targets Windows 11. Detected: $($operatingSystem.Caption), build $($operatingSystem.BuildNumber)."
    }

    if ([string]::IsNullOrWhiteSpace([string]$current.DisplayVersion)) {
        throw 'Windows DisplayVersion could not be determined.'
    }

    $description = "Pin Windows 11 feature updates to $($current.DisplayVersion)"
    if ($PSCmdlet.ShouldProcess($policyPath, $description)) {
        if (-not (Test-Path -LiteralPath $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }

        New-ItemProperty -Path $policyPath -Name 'ProductVersion' -PropertyType String -Value 'Windows 11' -Force | Out-Null
        New-ItemProperty -Path $policyPath -Name 'TargetReleaseVersion' -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $policyPath -Name 'TargetReleaseVersionInfo' -PropertyType String -Value $current.DisplayVersion -Force | Out-Null
    }
}
else {
    if ($PSCmdlet.ShouldProcess($policyPath, 'Remove local Windows feature-release target policy')) {
        if (Test-Path -LiteralPath $policyPath) {
            foreach ($name in @('ProductVersion', 'TargetReleaseVersion', 'TargetReleaseVersionInfo')) {
                Remove-ItemProperty -Path $policyPath -Name $name -ErrorAction SilentlyContinue
            }
        }
    }
}

if ($RestartUpdateService -and $PSCmdlet.ShouldProcess('wuauserv', 'Restart Windows Update service')) {
    Restart-Service -Name 'wuauserv' -Force
}

if (Test-Path -LiteralPath $policyPath) {
    Get-ItemProperty -Path $policyPath |
        Select-Object ProductVersion, TargetReleaseVersion, TargetReleaseVersionInfo
}
