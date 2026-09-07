@echo off
rem Legacy source command. Compare with current official Chocolatey instructions.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
if errorlevel 1 exit /b %errorlevel%
set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
