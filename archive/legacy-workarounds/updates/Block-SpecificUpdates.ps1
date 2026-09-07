#Requires -RunAsAdministrator



# Definition der zu blockierenden KBs

$KBsToBlock = @("KB5063878", "KB5062660") # KB-Nummern mit "KB"



# 1. Windows Update und BITS-Dienst stoppen

Write-Host "Stoppe Windows Update und BITS Dienste..." -ForegroundColor Yellow

Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue

Stop-Service -Name "bits" -Force -ErrorAction SilentlyContinue

Write-Host "Dienste erfolgreich gestoppt." -ForegroundColor Green



# Kurze Pause um sicherzugehen, dass die Dienste down sind

Start-Sleep -Seconds 2



# 2. Inhalt des SoftwareDistribution\Download Ordners löschen

$DownloadPath = "C:\Windows\SoftwareDistribution\Download"

Write-Host "Lösche Inhalte von: $DownloadPath" -ForegroundColor Yellow



if (Test-Path $DownloadPath) {

    try {

        Get-ChildItem -Path $DownloadPath -Recurse | Remove-Item -Force -Recurse -ErrorAction Stop

        Write-Host "Download-Ordner erfolgreich geleert." -ForegroundColor Green

    }

    catch {

        Write-Host "WARNUNG: Konnte nicht alle Dateien löschen. Möglicherweise sind einige noch gesperrt." -ForegroundColor Red

        Write-Host "Fehlermeldung: $($_.Exception.Message)" -ForegroundColor Red

    }

} else {

    Write-Host "WARNUNG: Der Pfad $DownloadPath wurde nicht gefunden." -ForegroundColor Red

}



# 3. Dienste wieder starten

Write-Host "Starte Windows Update und BITS Dienste neu..." -ForegroundColor Yellow

Start-Service -Name "bits" -ErrorAction SilentlyContinue

Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

Write-Host "Dienste erfolgreich gestartet." -ForegroundColor Green



# 4. PSWindowsUpdate Modul installieren und konfigurieren

Write-Host "`nÜberprüfe PSWindowsUpdate Modul..." -ForegroundColor Cyan



if (Get-Module -ListAvailable -Name PSWindowsUpdate) {

    Write-Host "Modul ist bereits installiert." -ForegroundColor Green

    # Modul importieren

    Import-Module PSWindowsUpdate -Force -Verbose:$false

} else {

    Write-Host "Modul ist nicht installiert. Installiere es jetzt..." -ForegroundColor Yellow

    try {

        # Repository vertrauen und Modul installieren

        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction Stop

        Install-Module -Name PSWindowsUpdate -Force -AllowClobber -ErrorAction Stop

        Import-Module PSWindowsUpdate -Force -Verbose:$false

        Write-Host "Modul erfolgreich installiert und importiert." -ForegroundColor Green

    }

    catch {

        Write-Host "FEHLER: Konnte das PSWindowsUpdate-Modul nicht installieren." -ForegroundColor Red

        Write-Host "Stellen Sie sicher, dass Sie eine Internetverbindung haben." -ForegroundColor Red

        Write-Host "Fehlermeldung: $($_.Exception.Message)" -ForegroundColor Red

        exit 1

    }

}



# Temporäre Ausführungsrichtlinie für diese Sitzung setzen

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force



# 5. Spezifische Updates verstecken

Write-Host "`nVersuche, die folgenden Updates zu verstecken: $($KBsToBlock -join ', ')" -ForegroundColor Cyan



foreach ($KB in $KBsToBlock) {

    try {

        Write-Host "Verstecke Update $KB..." -ForegroundColor Yellow

        # Prüfen, ob das Update bereits versteckt ist

        $IsHidden = Get-WindowsUpdate -IsHidden | Where-Object { $_.KB -contains $KB.Replace('KB', '') }

        

        if (-not $IsHidden) {

            Hide-WindowsUpdate -KBArticleID $KB -Verbose -ErrorAction Stop

            Write-Host "Erfolg: $KB wurde versteckt." -ForegroundColor Green

        } else {

            Write-Host "Info: $KB war bereits versteckt." -ForegroundColor Blue

        }

    }

    catch {

        Write-Host "FEHLER: Konnte $KB nicht verstecken." -ForegroundColor Red

        Write-Host "Fehlermeldung: $($_.Exception.Message)" -ForegroundColor Red

    }

}



# 6. Erfolgsüberprüfung

Write-Host "`n--- Überprüfung ---" -ForegroundColor Cyan

Write-Host "Liste aller aktuell versteckten Updates:" -ForegroundColor White

try {

    $HiddenUpdates = Get-WindowsUpdate -IsHidden | Select-Object Title, KB, Size

    if ($HiddenUpdates) {

        $HiddenUpdates | Format-Table -AutoSize

    } else {

        Write-Host "Keine versteckten Updates gefunden." -ForegroundColor Yellow

    }



    # Prüfen, ob unsere Ziele-KBs in der Liste der Versteckten sind

    $SuccessfulBlocks = @()

    foreach ($KB in $KBsToBlock) {

        $KBNumber = $KB.Replace('KB', '')

        if ($HiddenUpdates.KB -contains $KBNumber) {

            $SuccessfulBlocks += $KB

        }

    }



    if ($SuccessfulBlocks) {

        Write-Host "`nErfolg: Folgende Updates wurden blockiert: $($SuccessfulBlocks -join ', ')" -ForegroundColor Green

    } else {

        Write-Host "`nWarnung: Keines der Ziel-Updates konnte in der Liste der versteckten Updates gefunden werden." -ForegroundColor Red

    }

}

catch {

    Write-Host "Fehler bei der Überprüfung der versteckten Updates." -ForegroundColor Red

}



Write-Host "`nSkript abgeschlossen." -ForegroundColor Cyan