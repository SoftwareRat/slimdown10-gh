@echo off
TITLE WS-Discovery activator
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
ECHO Enabling Web Services Dynamic Discovery...

sc config FDResPub start= demand >nul 2>&1
sc config fdPHost start= demand >nul 2>&1

ECHO.
ECHO Done!
ECHO.
ECHO Web Services for Devices (WSD) based printing should work again.
ECHO.
PAUSE

:end
exit
