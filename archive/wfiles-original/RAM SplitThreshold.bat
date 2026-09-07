@echo off
title SvcHostSplitThreshold Selector

echo Wähle die Version basierend auf deinem RAM:
echo ==========================================
echo [1] 4GB RAM
echo [2] 8GB RAM
echo [3] 16GB RAM
echo [4] 32GB RAM
echo ==========================================
set /p choice=Gebe die Zahl (1-4) ein, um fortzufahren: 

if "%choice%"=="1" goto Version4GB
if "%choice%"=="2" goto Version8GB
if "%choice%"=="3" goto Version16GB
if "%choice%"=="4" goto Version32GB
echo Ungültige Auswahl! Bitte wähle eine Zahl zwischen 1 und 4.
pause
exit /b

:Version4GB
echo Version für 4GB RAM wird angewendet...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d 68689924 /f
goto End

:Version8GB
echo Version für 8GB RAM wird angewendet...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d 137779208 /f
goto End

:Version16GB
echo Version für 16GB RAM wird angewendet...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d 16777216 /f
goto End

:Version32GB
echo Version für 32GB RAM wird angewendet...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d 33554432 /f
goto End

:End
echo Die Änderungen wurden erfolgreich vorgenommen.
pause
exit