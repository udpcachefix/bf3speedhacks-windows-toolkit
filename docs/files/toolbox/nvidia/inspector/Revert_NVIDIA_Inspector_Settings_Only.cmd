@echo off
setlocal EnableExtensions
title Revert NVIDIA Inspector Settings Only

set "SCRIPT_DIR=%~dp0"
set "NIP_FILE=%SCRIPT_DIR%NVIDIA_Inspector_Default.nip"
set "INSPECTOR=%SCRIPT_DIR%inspector.exe"
set "DOWNLOAD_URL=https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe"

echo.
echo Reverting NVIDIA Inspector Base Profile...
echo.

if not exist "%NIP_FILE%" (
    echo ERROR: "%NIP_FILE%" was not found.
    echo Keep this CMD file and NVIDIA_Inspector_Default.nip in the same folder.
    echo.
    pause
    exit /b 1
)

if not exist "%INSPECTOR%" (
    echo NVIDIA Inspector was not found. Downloading inspector.exe...
    curl.exe -L --fail --silent --show-error "%DOWNLOAD_URL%" -o "%INSPECTOR%"
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to download inspector.exe.
        echo Place inspector.exe in this folder and run this file again.
        echo.
        pause
        exit /b 1
    )
)

"%INSPECTOR%" -silentImport -silent "%NIP_FILE%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo ERROR: NVIDIA Inspector returned exit code %RC%.
    echo.
    pause
    exit /b %RC%
)

echo.
echo NVIDIA Inspector default profile imported.
echo.
pause
exit /b 0
