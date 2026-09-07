@echo off
:menu
echo =======================================
echo        Windows Firewall Control
echo =======================================
echo.
echo 1. Turn Firewall ON (All Profiles)
echo 2. Turn Firewall OFF (All Profiles)
echo 3. Exit
echo.
set /p choice="Choose an option (1-3): "

if %choice%==1 goto turn_on
if %choice%==2 goto turn_off
if %choice%==3 goto exit
goto menu

:turn_on
echo Turning Windows Firewall ON (All Profiles)...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile" /v EnableFirewall /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile" /v EnableFirewall /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile" /v EnableFirewall /t REG_DWORD /d 1 /f
echo Windows Firewall is now ON for all profiles.
pause
goto menu

:turn_off
echo Turning Windows Firewall OFF (All Profiles)...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile" /v EnableFirewall /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile" /v EnableFirewall /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile" /v EnableFirewall /t REG_DWORD /d 0 /f
echo Windows Firewall is now OFF for all profiles.
pause
goto menu

:exit
echo Exiting...
exit