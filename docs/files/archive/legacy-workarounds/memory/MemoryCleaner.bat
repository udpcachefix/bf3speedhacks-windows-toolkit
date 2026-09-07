@echo off
rem Legacy source example. Not a maintained or verified memory cleaner.

:loop
set "free_memory="

for /f "tokens=2" %%a in ('typeperf "\Memory\Cache Bytes" -sc 1 ^| findstr /r /c:"[0-9][0-9]*\.[0-9][0-9]*"') do set "free_memory=%%a"

if defined free_memory (
    set /a "free_memory_gb=free_memory / 1024 / 1024 / 1024"
    if %free_memory_gb% gtr 8 (
        echo Clearing standby memory...
        wmic.exe /Namespace:\\root\cimv2 Path Win32_PerfFormattedData_PerfOS_Memory Call EmptyWorkingSet
        echo Standby memory cleared.
    )
)

timeout /t 600 /nobreak >nul
goto loop
