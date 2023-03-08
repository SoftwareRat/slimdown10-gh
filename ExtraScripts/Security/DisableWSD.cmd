@echo off
TITLE WS-Discovery deactivator
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
ECHO Disabling Web Services Dynamic Discovery...

net stop FDResPub /y >nul 2>&1
net stop fdPHost /y >nul 2>&1
sc config FDResPub start= disabled >nul 2>&1
sc config fdPHost start= disabled >nul 2>&1

ECHO.
ECHO Done!
ECHO.
ECHO WARNING!
ECHO Web Services for Devices (WSD) based printing won't be available now.
ECHO.
PAUSE

:end
exit
