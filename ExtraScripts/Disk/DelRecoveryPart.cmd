@echo off

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
 goto end
)

echo Disabling Recovery Mode...

bcdedit /set bootstatuspolicy IgnoreAllFailures >nul 2>&1
bcdedit /set recoveryenabled No >nul 2>&1
bcdedit /set {default} bootstatuspolicy IgnoreAllFailures >nul 2>&1
bcdedit /set {default} recoveryenabled No >nul 2>&1
reagentc.exe /disable >nul 2>&1
echo Done!

echo Deleting Recovery Partition...

echo select disk ^0>"%TEMP%\dpart_script.txt"
echo list partition>>"%TEMP%\dpart_script.txt"

set RecoveryPart=
for /f "tokens=2,3 delims= " %%a in ('diskpart /s "%TEMP%\dpart_script.txt" 2^>nul ^| findstr /r /c:" Partition [0-9] "') do (
 if "%%b"=="Recovery" (
  echo %%a|findstr /r /c:"^[1-9]$" >nul 2>&1 && set "RecoveryPart=%%a"
 )
)

if "%RecoveryPart%"=="" (
 echo ERROR: Recovery partition not found, so nothing is deleted!
 goto skipDelRecovery
)


echo select disk ^0>"%TEMP%\dpart_script.txt"
echo select partition ^%RecoveryPart%>>"%TEMP%\dpart_script.txt"
echo delete partition noerr override>>"%TEMP%\dpart_script.txt"

diskpart /s "%TEMP%\dpart_script.txt" >nul 2>&1
echo Done!

:skipDelRecovery


echo Extending Boot Volume to cover free space...

echo select disk ^0>"%TEMP%\dpart_script.txt"
echo list volume>>"%TEMP%\dpart_script.txt"

set BootVolNum=
for /f "tokens=2,9 delims= " %%a in ('diskpart /s "%TEMP%\dpart_script.txt" 2^>nul ^| findstr /r /c:" Volume [0-9] "') do (
 if "%%b"=="Boot" set "BootVolNum=%%a"
)

echo %BootVolNum%|findstr /r /c:"^[1-9]$" >nul 2>&1 || set BootVolNum=

if "%BootVolNum%"=="" (
 echo ERROR: Boot Volume not found, so no expansion is done!
 goto skipExtBoot
)

echo select disk ^0>"%TEMP%\dpart_script.txt"
echo select volume ^%BootVolNum%>>"%TEMP%\dpart_script.txt"
echo extend noerr>>"%TEMP%\dpart_script.txt"

diskpart /s "%TEMP%\dpart_script.txt" >nul 2>&1
echo Done!

:skipExtBoot

set BootVolNum=
set RecoveryPart=
del /q /f "%TEMP%\dpart_script.txt" >nul 2>&1

:end
echo.
pause
