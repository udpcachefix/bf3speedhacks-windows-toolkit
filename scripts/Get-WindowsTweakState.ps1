#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-StateQuery {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Query
    )

    try {
        & $Query
    }
    catch {
        [pscustomobject]@{
            Status = 'Unavailable'
            Error  = $_.Exception.Message
        }
    }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$os = Invoke-StateQuery {
    Get-CimInstance -ClassName Win32_OperatingSystem |
        Select-Object Caption, Version, BuildNumber, OSArchitecture, LastBootUpTime
}

$firewall = Invoke-StateQuery {
    Get-NetFirewallProfile |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
}

$sleepStates = Invoke-StateQuery {
    $output = & powercfg.exe /availablesleepstates 2>&1
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join [Environment]::NewLine)
    }
}

$driverPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$driverPolicy = Invoke-StateQuery {
    $value = Get-ItemPropertyValue -Path $driverPolicyPath -Name 'ExcludeWUDriversInQualityUpdate' -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Path     = $driverPolicyPath
        RawValue = $value
        Meaning  = if ($value -eq 1) { 'Drivers excluded from quality updates' } else { 'No local exclusion detected' }
    }
}

$bootConfiguration = Invoke-StateQuery {
    $output = & bcdedit.exe /enum '{current}' 2>&1
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join [Environment]::NewLine)
    }
}

$restorePoints = Invoke-StateQuery {
    Get-ComputerRestorePoint |
        Sort-Object SequenceNumber -Descending |
        Select-Object -First 10 SequenceNumber, Description, CreationTime, RestorePointType
}

$serviceNames = @(
    'BITS',
    'CryptSvc',
    'mpssvc',
    'SecurityHealthService',
    'SysMain',
    'UsoSvc',
    'wscsvc',
    'wuauserv'
)

$services = Invoke-StateQuery {
    foreach ($name in $serviceNames) {
        $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction SilentlyContinue
        if ($null -eq $service) {
            [pscustomobject]@{ Name = $name; State = 'NotFound'; StartMode = $null }
        }
        else {
            [pscustomobject]@{ Name = $service.Name; State = $service.State; StartMode = $service.StartMode }
        }
    }
}

$result = [pscustomobject]@{
    CollectedAt       = Get-Date
    ComputerName      = $env:COMPUTERNAME
    IsAdministrator   = $isAdministrator
    OperatingSystem   = $os
    FirewallProfiles  = $firewall
    AvailableSleep    = $sleepStates
    DriverUpdatePolicy = $driverPolicy
    BootConfiguration = $bootConfiguration
    RecentRestorePoints = $restorePoints
    SelectedServices  = $services
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 6
}
else {
    $result
}
