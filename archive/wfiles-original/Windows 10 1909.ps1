# List of services to be set to Automatic
$automaticServices = @("BrokerInfrastructure", "camsvc", "CoreMessagingRegistrar", "CryptSvc", "DcomLaunch", "DeviceInstall", "Dhcp", "LSM", "nsi", "NVDisplay.ContainerLocalSystem", "Power", "RpcSs", "RpcEptMapper", "ProfSvc", "Audiosrv", "AudioEndpointBuilder", "Wcmsvc", "Winmgmt", "sppsvc", "gpsvc", "SystemEventsBroker", "UserManager")

# List of services to be set to Manual
$manualServices = @("embeddedmode", "wlpasvc", "NetSetupSvc", "DmEnrollmentSvc", "PerfHost", "StateRepository", "vds", "msiserver", "TrustedInstaller")

# Set the startup type of the services
foreach ($service in $automaticServices) {
    Set-Service -Name $service -StartupType Automatic
}

foreach ($service in $manualServices) {
    Set-Service -Name $service -StartupType Manual
}

# Get all the services
$allServices = Get-Service | Select-Object -ExpandProperty Name

# Disable the services not listed
foreach ($service in $allServices) {
    if ($service -notin $automaticServices -and $service -notin $manualServices) {
        Set-Service -Name $service -StartupType Disabled
    }
}
