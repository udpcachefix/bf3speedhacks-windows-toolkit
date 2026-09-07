#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'packages\chocolatey-packages.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$choco = Get-Command -Name choco.exe -ErrorAction SilentlyContinue
if ($null -eq $choco) {
    throw 'Chocolatey is not installed or choco.exe is not available in PATH. Use the current official Chocolatey installation instructions first.'
}

$packages = @(
    Get-Content -LiteralPath $ManifestPath |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') } |
        Sort-Object -Unique
)

if ($packages.Count -eq 0) {
    throw "No packages were found in '$ManifestPath'."
}

Write-Host "Packages selected: $($packages.Count)"
$packages | ForEach-Object { Write-Host "  $_" }

if ($PSCmdlet.ShouldProcess(($packages -join ', '), 'Install Chocolatey packages')) {
    & $choco.Source install @packages --yes --limit-output
    if ($LASTEXITCODE -notin @(0, 1641, 3010)) {
        throw "Chocolatey failed with exit code $LASTEXITCODE."
    }

    if ($LASTEXITCODE -in @(1641, 3010)) {
        Write-Warning 'Chocolatey completed and reported that a restart is required.'
    }
}
