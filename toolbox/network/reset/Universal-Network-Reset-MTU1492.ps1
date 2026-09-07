#requires -Version 5.1
$ErrorActionPreference = 'Continue'
$TargetMtu = 1492

function Write-Ok([string]$Text)   { Write-Host "[ OK ] $Text" -ForegroundColor Green }
function Write-Warn([string]$Text) { Write-Host "[WARN] $Text" -ForegroundColor Yellow }
function Write-Info([string]$Text) { Write-Host "[INFO] $Text" -ForegroundColor Gray }

# Self-elevate
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`""
    )
    exit
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Windows 11 - Universal Network Reset + MTU 1492" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resets the PRIMARY PHYSICAL Ethernet/WLAN adapter only." -ForegroundColor DarkGray
Write-Host "VPN, Hyper-V/virtual adapters, bindings, DNS and IP addressing are not reset." -ForegroundColor DarkGray
Write-Host ""

# ------------------------------------------------------------
# Find primary physical Ethernet/WLAN adapter.
# A VPN may own the system default route, so first restrict the
# search to hardware adapters and then rank their own default routes.
# ------------------------------------------------------------

try {
    $physical = @(Get-NetAdapter -Physical -ErrorAction Stop |
        Where-Object { $_.Status -eq 'Up' })
}
catch {
    Write-Warn "Get-NetAdapter -Physical failed: $($_.Exception.Message)"
    $physical = @()
}

if (-not $physical -or $physical.Count -eq 0) {
    Write-Host "[ERROR] No active physical Ethernet/WLAN adapter found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$ipv4If = @(Get-NetIPInterface -AddressFamily IPv4 -ErrorAction SilentlyContinue)
$defaultRoutes = @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue)

$ranked = foreach ($a in $physical) {
    $ifInfo = $ipv4If | Where-Object { $_.InterfaceIndex -eq $a.ifIndex } | Select-Object -First 1
    $route = $defaultRoutes | Where-Object { $_.InterfaceIndex -eq $a.ifIndex } |
        Sort-Object RouteMetric | Select-Object -First 1

    [pscustomobject]@{
        Adapter         = $a
        HasDefaultRoute = [bool]$route
        RouteMetric     = if ($route) { [int]$route.RouteMetric } else { 999999 }
        InterfaceMetric = if ($ifInfo) { [int]$ifInfo.InterfaceMetric } else { 999999 }
    }
}

$selected = $ranked |
    Sort-Object @{Expression='HasDefaultRoute';Descending=$true},
                @{Expression={ $_.RouteMetric + $_.InterfaceMetric };Ascending=$true} |
    Select-Object -First 1

$adapter = $selected.Adapter
$name = $adapter.Name
$ifIndex = $adapter.ifIndex

Write-Info "Selected adapter: $name"
Write-Info "Description     : $($adapter.InterfaceDescription)"
Write-Info "Interface index : $ifIndex"
Write-Info "Link speed      : $($adapter.LinkSpeed)"

# ------------------------------------------------------------
# Audit current state before touching anything.
# ------------------------------------------------------------

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$baseDir = if ($PSScriptRoot) { $PSScriptRoot } else { $env:TEMP }
$beforePath = Join-Path $baseDir "Network-Before-Universal-Reset-$stamp.txt"
$afterPath  = Join-Path $baseDir "Network-After-Universal-Reset-$stamp.txt"

try {
    @(
        "Captured: $(Get-Date -Format o)"
        ""
        "=== SELECTED ADAPTER ==="
        (Get-NetAdapter -Name $name | Format-List Name,InterfaceDescription,ifIndex,Status,LinkSpeed,MacAddress,DriverInformation | Out-String)
        "=== ADVANCED PROPERTIES ==="
        (Get-NetAdapterAdvancedProperty -Name $name -ErrorAction SilentlyContinue |
            Sort-Object DisplayName |
            Format-Table DisplayName,DisplayValue,RegistryKeyword,RegistryValue -AutoSize | Out-String)
        "=== RSS ==="
        (Get-NetAdapterRss -Name $name -ErrorAction SilentlyContinue | Format-List * | Out-String)
        "=== RSC ==="
        (Get-NetAdapterRsc -Name $name -ErrorAction SilentlyContinue | Format-List * | Out-String)
        "=== IPv4 INTERFACE ==="
        (Get-NetIPInterface -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Format-List * | Out-String)
        "=== IPv6 INTERFACE ==="
        (Get-NetIPInterface -InterfaceIndex $ifIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue | Format-List * | Out-String)
        "=== TCP GLOBAL ==="
        ((netsh int tcp show global) | Out-String)
        "=== TCP SUPPLEMENTAL ==="
        ((netsh int tcp show supplemental) | Out-String)
    ) | Set-Content -LiteralPath $beforePath -Encoding UTF8
    Write-Ok "Before-state audit saved: $beforePath"
}
catch {
    Write-Warn "Could not write full before-state audit: $($_.Exception.Message)"
}

# ------------------------------------------------------------
# 1) Reset exposed NIC Advanced Properties to the defaults
# supplied by the currently installed NIC driver.
# ------------------------------------------------------------

Write-Host ""
Write-Host "--- Driver properties -> driver defaults ---" -ForegroundColor Cyan

try {
    $props = @(Get-NetAdapterAdvancedProperty -Name $name -ErrorAction Stop |
        Where-Object { $_.RegistryKeyword } |
        Sort-Object RegistryKeyword -Unique)

    foreach ($p in $props) {
        try {
            Reset-NetAdapterAdvancedProperty `
                -Name $name `
                -RegistryKeyword $p.RegistryKeyword `
                -NoRestart `
                -ErrorAction Stop
            Write-Ok "$($p.DisplayName) [$($p.RegistryKeyword)]"
        }
        catch {
            Write-Warn "$($p.DisplayName) [$($p.RegistryKeyword)]: $($_.Exception.Message)"
        }
    }
}
catch {
    Write-Warn "Driver-property reset could not be enumerated: $($_.Exception.Message)"
}

# ------------------------------------------------------------
# 2) Return Windows TCP behavior to a conservative normal state.
# Only settings that were part of the earlier tuning are touched.
# ------------------------------------------------------------

Write-Host ""
Write-Host "--- Windows TCP stack -> normal baseline ---" -ForegroundColor Cyan

$tcpCommands = @(
    'netsh int tcp set global rss=enabled',
    'netsh int tcp set global autotuninglevel=normal',
    'netsh int tcp set global ecncapability=disabled',
    'netsh int tcp set global initialrto=3000',
    'netsh int tcp set global rsc=enabled',
    'netsh int tcp set global nonsackrttresiliency=disabled',
    'netsh int tcp set global maxsynretransmissions=2',
    'netsh int tcp set global fastopen=enabled',
    'netsh int tcp set global fastopenfallback=enabled',
    'netsh int tcp set global hystart=enabled'
)

foreach ($cmd in $tcpCommands) {
    Write-Info $cmd
    $output = cmd.exe /d /c $cmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok ($output -join ' ')
    }
    else {
        Write-Warn (($output -join ' ').Trim())
    }
}

# Undo an explicitly forced supplemental congestion provider.
# "default" is attempted rather than hard-coding CTCP/CUBIC.
Write-Info 'netsh int tcp set supplemental template=internet congestionprovider=default'
$suppOut = cmd.exe /d /c 'netsh int tcp set supplemental template=internet congestionprovider=default' 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Ok ($suppOut -join ' ')
}
else {
    Write-Warn "Supplemental congestion-provider reset was not accepted on this Windows build. It was left unchanged."
    Write-Warn (($suppOut -join ' ').Trim())
}

# ------------------------------------------------------------
# 3) Enable RSS/RSC on the selected physical adapter where supported.
# Unsupported adapters (often some WLAN drivers) are simply skipped.
# ------------------------------------------------------------

Write-Host ""
Write-Host "--- Adapter RSS/RSC ---" -ForegroundColor Cyan

try {
    Enable-NetAdapterRss -Name $name -ErrorAction Stop
    Write-Ok "RSS enabled"
}
catch {
    Write-Warn "RSS not changed/supported: $($_.Exception.Message)"
}

try {
    Enable-NetAdapterRsc -Name $name -IPv4 -IPv6 -ErrorAction Stop
    Write-Ok "RSC IPv4/IPv6 enabled"
}
catch {
    Write-Warn "RSC not changed/supported: $($_.Exception.Message)"
}

# ------------------------------------------------------------
# 4) Force requested MTU 1492 on the primary physical adapter.
# This is a deliberate override, NOT the normal Ethernet default.
# IPv4 and IPv6 are both set to 1492.
# ------------------------------------------------------------

Write-Host ""
Write-Host "--- MTU -> $TargetMtu ---" -ForegroundColor Cyan

try {
    Set-NetIPInterface -InterfaceIndex $ifIndex -AddressFamily IPv4 -NlMtuBytes $TargetMtu -ErrorAction Stop
    Write-Ok "IPv4 MTU = $TargetMtu on $name"
}
catch {
    Write-Warn "PowerShell IPv4 MTU command failed; trying netsh."
    $mtuOut = netsh interface ipv4 set subinterface "$name" mtu=$TargetMtu store=persistent 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Ok "IPv4 MTU = $TargetMtu via netsh" }
    else { Write-Warn ($mtuOut -join ' ') }
}

try {
    Set-NetIPInterface -InterfaceIndex $ifIndex -AddressFamily IPv6 -NlMtuBytes $TargetMtu -ErrorAction Stop
    Write-Ok "IPv6 MTU = $TargetMtu on $name"
}
catch {
    Write-Warn "PowerShell IPv6 MTU command failed; trying netsh."
    $mtuOut = netsh interface ipv6 set subinterface "$name" mtu=$TargetMtu store=persistent 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Ok "IPv6 MTU = $TargetMtu via netsh" }
    else { Write-Warn ($mtuOut -join ' ') }
}

# ------------------------------------------------------------
# Restart only the selected physical adapter.
# This does not remove IPv4/IPv6, VPN filters, Hyper-V bindings,
# DNS configuration, DHCP/static addresses or virtual adapters.
# ------------------------------------------------------------

Write-Host ""
Write-Host "--- Restart adapter ---" -ForegroundColor Cyan

try {
    Restart-NetAdapter -Name $name -Confirm:$false -ErrorAction Stop
    Write-Ok "Adapter restarted"
}
catch {
    Write-Warn "Adapter restart failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 3

# ------------------------------------------------------------
# Final state
# ------------------------------------------------------------

try {
    @(
        "Captured: $(Get-Date -Format o)"
        ""
        "=== SELECTED ADAPTER ==="
        (Get-NetAdapter -Name $name | Format-List Name,InterfaceDescription,ifIndex,Status,LinkSpeed,MacAddress,DriverInformation | Out-String)
        "=== ADVANCED PROPERTIES ==="
        (Get-NetAdapterAdvancedProperty -Name $name -ErrorAction SilentlyContinue |
            Sort-Object DisplayName |
            Format-Table DisplayName,DisplayValue,RegistryKeyword,RegistryValue -AutoSize | Out-String)
        "=== RSS ==="
        (Get-NetAdapterRss -Name $name -ErrorAction SilentlyContinue | Format-List * | Out-String)
        "=== RSC ==="
        (Get-NetAdapterRsc -Name $name -ErrorAction SilentlyContinue | Format-List * | Out-String)
        "=== IPv4 MTU ==="
        (Get-NetIPInterface -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Format-Table InterfaceAlias,InterfaceIndex,NlMtu,InterfaceMetric,ConnectionState -AutoSize | Out-String)
        "=== IPv6 MTU ==="
        (Get-NetIPInterface -InterfaceIndex $ifIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue |
            Format-Table InterfaceAlias,InterfaceIndex,NlMtu,InterfaceMetric,ConnectionState -AutoSize | Out-String)
        "=== TCP GLOBAL ==="
        ((netsh int tcp show global) | Out-String)
        "=== TCP SUPPLEMENTAL ==="
        ((netsh int tcp show supplemental) | Out-String)
    ) | Set-Content -LiteralPath $afterPath -Encoding UTF8
    Write-Ok "After-state audit saved: $afterPath"
}
catch {
    Write-Warn "Could not write full after-state audit: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " RESULT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Get-NetAdapter -Name $name |
    Format-Table Name,Status,LinkSpeed,InterfaceDescription -AutoSize

Get-NetIPInterface -InterfaceIndex $ifIndex -ErrorAction SilentlyContinue |
    Where-Object { $_.AddressFamily -in 'IPv4','IPv6' } |
    Format-Table InterfaceAlias,AddressFamily,NlMtu,InterfaceMetric,ConnectionState -AutoSize

Write-Host ""
netsh int tcp show global

Write-Host ""
Write-Host "Done. Reboot Windows once before comparing latency/throughput." -ForegroundColor Green
Write-Host "Note: MTU 1492 is intentionally forced by request; Ethernet's usual default is 1500." -ForegroundColor Yellow
Read-Host "Press Enter to exit"
