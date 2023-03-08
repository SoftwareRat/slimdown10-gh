@echo off
TITLE Check system drive
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

FSUTIL USN DELETEJOURNAL /D %SystemDrive% >NUL 2>&1
ECHO Y|CHKDSK /F %SystemDrive% >NUL 2>&1

ECHO.
ECHO Please REBOOT to check your system drive!
ECHO.
PAUSE

:end
exit
