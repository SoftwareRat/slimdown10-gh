@echo off
TITLE IPsec activator
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
ECHO Enabling IPsec services...

sc config IKEEXT start= demand >nul 2>&1
sc config PolicyAgent start= demand >nul 2>&1

ECHO.
ECHO Done!
ECHO.
PAUSE

:end
exit
