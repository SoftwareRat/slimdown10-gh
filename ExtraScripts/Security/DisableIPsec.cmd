@echo off
TITLE IPsec deactivator
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
ECHO Disabling IPsec services...

net stop IKEEXT /y >nul 2>&1
net stop PolicyAgent /y >nul 2>&1
sc config IKEEXT start= disabled >nul 2>&1
sc config PolicyAgent start= disabled >nul 2>&1

ECHO.
ECHO Done!
ECHO.
PAUSE

:end
exit
