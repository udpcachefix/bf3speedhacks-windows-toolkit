@echo off
setlocal

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Windows-Orphan-Cleanup-Audit.ps1" -Gui

endlocal
