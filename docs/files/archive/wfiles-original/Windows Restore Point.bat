@echo off
echo Deleting all restore points...
vssadmin delete shadows /all /quiet
if %errorlevel% == 0 (
    echo Restore points deleted successfully.
) else (
    echo Failed to delete restore points.
)

echo Waiting for 5 minutes before creating a new restore point...
timeout /t 300 /nobreak > NUL

echo Creating a new restore point...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Custom Restore Point", 100, 7
if %errorlevel% == 0 (
    echo Restore point created successfully.
) else (
    echo Failed to create restore point.
)