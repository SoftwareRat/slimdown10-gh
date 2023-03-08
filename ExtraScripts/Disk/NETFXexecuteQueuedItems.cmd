@ECHO OFF
TITLE Compiling NET Framework...
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
 goto noNET40x64
)

if not exist "%windir%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto noNET20x86
ECHO Compiling NET Framework 2.0 (32-bit)
"%windir%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" executeQueuedItems >NUL 2>NUL
:noNET20x86
if not exist "%windir%\Microsoft.NET\Framework64\v2.0.50727\ngen.exe" goto noNET20x64
ECHO Compiling NET Framework 2.0 (64-bit)
"%windir%\Microsoft.NET\Framework64\v2.0.50727\ngen.exe" executeQueuedItems >NUL 2>NUL
:noNET20x64
if not exist "%windir%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" goto noNET40x86
ECHO Compiling NET Framework 4.0 (32-bit)
"%windir%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" executeQueuedItems >NUL 2>NUL
:noNET40x86
if not exist "%windir%\Microsoft.NET\Framework64\v4.0.30319\ngen.exe" goto noNET40x64
ECHO Compiling NET Framework 4.0 (64-bit)
"%windir%\Microsoft.NET\Framework64\v4.0.30319\ngen.exe" executeQueuedItems >NUL 2>NUL
:noNET40x64
exit
