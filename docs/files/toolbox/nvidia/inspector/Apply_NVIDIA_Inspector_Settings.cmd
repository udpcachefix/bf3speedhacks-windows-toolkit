@echo off
setlocal EnableExtensions

title NVIDIA Inspector Settings Importer

set "SCRIPT_DIR=%~dp0"
set "NIP_FILE=%SCRIPT_DIR%NVIDIA_Inspector_Settings.nip"
set "INSPECTOR=%SCRIPT_DIR%inspector.exe"
set "DOWNLOAD_URL=https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe"

echo.
echo NVIDIA Inspector Settings Importer
echo ================================
echo.

if not exist "%NIP_FILE%" (
    echo ERROR: "%NIP_FILE%" was not found.
    echo Keep this CMD file and NVIDIA_Inspector_Settings.nip in the same folder.
    echo.
    pause
    exit /b 1
)

if not exist "%INSPECTOR%" (
    echo NVIDIA Inspector was not found in this folder.
    echo Downloading inspector.exe...
    echo.

    curl.exe -L --fail --silent --show-error "%DOWNLOAD_URL%" -o "%INSPECTOR%"
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to download inspector.exe.
        echo You can manually place inspector.exe next to this CMD file and run it again.
        echo.
        pause
        exit /b 1
    )
)

echo Importing NVIDIA Inspector Base Profile settings...
echo.

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
echo Settings imported successfully.
echo.
pause
exit /b 0
