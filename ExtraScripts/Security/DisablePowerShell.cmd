@echo off
TITLE Disable PowerShell

fsutil dirty query %systemdrive% >nul 2>&1
if ERRORLEVEL 1 (
 ECHO.
 ECHO.
 ECHO ===================================================================
 ECHO This script needs Administrator permissions!
 ECHO.
 ECHO Please run it as the Administrator or disable User Account Control.
 ECHO ===================================================================
 ECHO.
 PAUSE >NUL
 goto end
)

echo.
echo Disabling PowerShell...

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\powershell.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\systray.exe" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\pwsh.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\systray.exe" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\powershell_ise.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\systray.exe" /f >nul

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v "1" /t REG_SZ /d "powershell.exe" /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v "2" /t REG_SZ /d "powershell_ise.exe" /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v "3" /t REG_SZ /d "pwsh.exe" /f >nul

ECHO.
ECHO Done!
ECHO.
PAUSE
:end
