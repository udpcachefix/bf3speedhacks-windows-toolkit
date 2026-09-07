@echo off
rem UNSAFE LEGACY SOURCE: deletes all Volume Shadow Copy snapshots.

echo Deleting all restore points...
vssadmin delete shadows /all /quiet

if %errorlevel% == 0 (
    echo Restore points deleted successfully.
) else (
    echo Failed to delete restore points.
)

echo Creating a new restore point...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Custom Restore Point", 100, 7

if %errorlevel% == 0 (
    echo Restore point requested successfully.
) else (
    echo Failed to request a restore point.
)
