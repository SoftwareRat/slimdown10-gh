@echo off
TITLE Unmount and clean up script
CLS

::
:: This script is only needed if execution of Slimdown10 gets interrupted,
:: leaving garbage behind.
::
:: Orherwise, It has no effect because normally Slimdown10 has built in clean up.
::

REM Check admin rights
fsutil dirty query %systemdrive% >nul 2>&1
if ERRORLEVEL 1 (
 ECHO.
 ECHO.
 ECHO =============================================
 ECHO The script needs Administrator permissions!
 ECHO.
 ECHO Please run it as the Administrator.
 ECHO =============================================
 ECHO.
 PAUSE >NUL
 goto end
)

REM Check parenthesis in script PATH, which brakes subsequent for loops
set incorrectPath=0

echo "%~dp0" | findstr /l /c:"(" >nul 2>&1 && set incorrectPath=1
echo "%~dp0" | findstr /l /c:")" >nul 2>&1 && set incorrectPath=1

if not "%incorrectPath%"=="0" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Script cannot be run from this location!
 ECHO Current location contatins parenthesis in the PATH.
 ECHO.
 ECHO Please copy and run script from Desktop or another directory!
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)

set DISM=
set "HostArchitecture=x86"
if exist "%WinDir%\SysWOW64" set "HostArchitecture=amd64"

if exist "%~dp0hotfixes\InternalDISM.txt" goto useInternalDISM
for /f "delims=" %%i in ('where dism 2^>nul') do (set "DISM=%%i")
if "%DISM%"=="" goto useInternalDISM
if not exist "%DISM%" goto useInternalDISM
%DISM% /English /? | findstr /l /i /c:"Version: 10.0.19041" >nul 2>&1 && goto skipInternalDISM
%DISM% /English /? | findstr /r /i /c:"Version: 10\.0\.1904[2-9]" >nul 2>&1 && goto skipInternalDISM
%DISM% /English /? | findstr /r /i /c:"Version: 10\.0\.190[5-9]" >nul 2>&1 && goto skipInternalDISM
%DISM% /English /? | findstr /r /i /c:"Version: 10\.0\.19[1-9]" >nul 2>&1 && goto skipInternalDISM
%DISM% /English /? | findstr /r /i /c:"Version: 10\.0\.[2-9]" >nul 2>&1 && goto skipInternalDISM
%DISM% /English /? | findstr /r /i /c:"Version: 10\.[1-9]" >nul 2>&1 && goto skipInternalDISM
%DISM% /English /? | findstr /r /i /c:"Version: 1[1-9]\." >nul 2>&1 && goto skipInternalDISM
:useInternalDISM
set "DISM=%~dp0tools\%HostArchitecture%\DISM\dism.exe"
:skipInternalDISM

ECHO.
ECHO.
ECHO ================================================================
ECHO Unmounting mounted registry keys...
ECHO ================================================================
ECHO.


reg unload HKLM\TK_DEFAULT >nul 2>&1
reg unload HKLM\TK_NTUSER >nul 2>&1
reg unload HKLM\TK_SOFTWARE >nul 2>&1
reg unload HKLM\TK_SYSTEM >nul 2>&1

ECHO.
ECHO Done!
ECHO.

ECHO.
ECHO.
ECHO ================================================================
ECHO Unmounting mounted images...
ECHO ================================================================
ECHO.


if exist "%~dp0mount\Windows\explorer.exe" (
 %DISM% /English /Unmount-Wim /MountDir:"%~dp0mount" /Discard
)

rd /s /q "%~dp0mount" >nul 2>&1
mkdir "%~dp0mount" >nul 2>&1

%DISM% /English /Cleanup-Mountpoints
del /q /f "%~dp0hotfixes\InternalDISM.txt" >nul 2>&1

ECHO.
ECHO.
ECHO All done!
ECHO.

ECHO.
ECHO Press any key to end the script.
ECHO.

PAUSE >NUL

:end
