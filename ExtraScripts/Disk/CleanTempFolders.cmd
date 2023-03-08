@echo off
TITLE Clean temporary files
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


CD /D "%LOCALAPPDATA%\Temp" >NUL 2>&1
CD | FINDSTR /R /I "\\Temp$" >NUL 2>&1
IF ERRORLEVEL 1 GOTO skipTemp1
ECHO Cleaning: "%LOCALAPPDATA%\Temp"
RD /S /Q . >NUL 2>&1
:skipTemp1

CD /D "%SystemRoot%\Temp" >NUL 2>&1
CD | FINDSTR /R /I "\\Temp$" >NUL 2>&1
IF ERRORLEVEL 1 GOTO skipTemp2
ECHO Cleaning: "%SystemRoot%\Temp"
RD /S /Q . >NUL 2>&1
:skipTemp2


ECHO.
ECHO Done!
ECHO.
PAUSE

:end
exit
