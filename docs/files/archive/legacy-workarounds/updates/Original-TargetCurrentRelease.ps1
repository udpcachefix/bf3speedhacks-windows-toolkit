#Requires -Version 5.1
#Requires -RunAsAdministrator

# Legacy source procedure. The maintained replacement also sets ProductVersion
# and provides a rollback mode.
$registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'

if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

Set-ItemProperty -Path $registryPath -Name 'TargetReleaseVersion' -Value 1 -Type DWord

$currentVersion = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
Set-ItemProperty -Path $registryPath -Name 'TargetReleaseVersionInfo' -Value $currentVersion -Type String

Restart-Service -Name 'wuauserv' -Force
Write-Host "Windows remains targeted to feature release: $currentVersion" -ForegroundColor Green
