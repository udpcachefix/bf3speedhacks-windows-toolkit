# List of services to be set to Manual
$manualServices = @("CoreMessaging", "DcomLaunch", "StateRepository")

# List of services to be set to Automatic
$automaticServices = @("Audiosrv", "LSM", "NVDisplayContainer", "Power", "prio_svc", "ProfSvc", "RpcEptMapper", "RpcSs", "STR")

# Set the startup type of the services
foreach ($service in $automaticServices) {
    Set-Service -Name $service -StartupType Automatic
}

foreach ($service in $manualServices) {
    Set-Service -Name $service -StartupType Manual
}

# Get all the services
$allServices = Get-Service | Select-Object -ExpandProperty Name

# Set all other services to Automatic
foreach ($service in $allServices) {
    if ($service -notin $automaticServices -and $service -notin $manualServices) {
        Set-Service -Name $service -StartupType Automatic
    }
}

# Disable the services not listed
foreach ($service in $allServices) {
    if ($service -notin $automaticServices -and $service -notin $manualServices) {
        Set-Service -Name $service -StartupType Disabled
    }
}
