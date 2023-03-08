@echo off
TITLE Enable automatic drivers updates
CLS

fsutil dirty query %systemdrive% >nul 2>&1
if ERRORLEVEL 1 (
 ECHO.
 ECHO =============================================
 ECHO This script needs Administrator permissions!
 ECHO.
 ECHO Please run it as the Administrator.
 ECHO =============================================
 ECHO.
 PAUSE >NUL
 goto end
)

ECHO.
ECHO Enabling automatic updates of drivers...

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /f >nul 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" /f >nul 2>nul

reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d "1" /f >nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching" /v "DontSearchWindowsUpdate" /f >nul 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching" /v "DriverUpdateWizardWuSearchEnabled" /f >nul 2>nul
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d "0" /f >nul

reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /f >nul 2>nul

ECHO.
ECHO Done!
ECHO.
PAUSE

:end
exit
