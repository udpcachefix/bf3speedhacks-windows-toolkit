# Definition der Pfade für die Registry
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

# Prüfen, ob der Pfad existiert, andernfalls erstellen
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

# Aktiviert die Zielversions-Richtlinie
Set-ItemProperty -Path $registryPath -Name "TargetReleaseVersion" -Value 1 -Type DWord

# Ermittelt die aktuell installierte Windows-Version (z.B. 22H2, 23H2)
$currentVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion

# Fixiert Windows auf die aktuelle Versionsnummer
Set-ItemProperty -Path $registryPath -Name "TargetReleaseVersionInfo" -Value $currentVersion -Type String

# Startet den Windows Update-Dienst neu, um Änderungen anzuwenden
Restart-Service -Name "wuauserv" -Force

Write-Host "Erfolgreich! Windows bleibt dauerhaft auf Version: $currentVersion" -ForegroundColor Green