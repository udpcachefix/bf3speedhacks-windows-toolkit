@echo off
powercfg.exe /setactive SCHEME_MIN
if errorlevel 1 (
    echo Failed to activate the High Performance power scheme.
    exit /b 1
)
echo High Performance power scheme activated.
