@echo off
TITLE Windows Update Toggler (Enabler/Disabler)
CLS

fsutil dirty query %SystemDrive% >nul 2>&1
if ERRORLEVEL 1 (
 ECHO.
 ECHO =============================================
 ECHO This tool needs Administrator permissions!
 ECHO.
 ECHO Please run it as the Administrator.
 ECHO =============================================
 ECHO.
 PAUSE >NUL
 goto end
)

sc qc UsoSvc | findstr "START_TYPE" | findstr "DISABLED" >nul 2>&1
if "%ERRORLEVEL%"=="0" (
 ECHO.
 ECHO Current Windows Update service status is: disabled
 ECHO.
 ECHO Enabling Windows Update service...
 sc config UsoSvc start= demand >nul 2>&1
 net start UsoSvc /y >nul 2>&1
 ECHO.
 ECHO Windows Update is now ENABLED.
 ECHO.
 PAUSE
 GOTO end
)

ECHO.
ECHO Current Windows Update service status is: enabled
ECHO.
ECHO Disabling Windows Update service...
net stop WaaSMedicSvc /y >nul 2>&1
net stop UsoSvc /y >nul 2>&1
sc config WaaSMedicSvc start= disabled >nul 2>&1
sc config UsoSvc start= disabled >nul 2>&1
if exist "%ProgramFiles%\Nsudo\NSudo.exe" (
 "%ProgramFiles%\Nsudo\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait schtasks /Delete /TN "Microsoft\Windows\WaaSMedic\PerformRemediation" /F >nul 2>&1
 "%ProgramFiles%\Nsudo\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait schtasks /Delete /TN "Microsoft\Windows\UpdateOrchestrator\Report policies" /F >nul 2>&1
 "%ProgramFiles%\Nsudo\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait schtasks /Delete /TN "Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" /F >nul 2>&1
 "%ProgramFiles%\Nsudo\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait schtasks /Delete /TN "Microsoft\Windows\UpdateOrchestrator\UpdateModelTask" /F >nul 2>&1
 "%ProgramFiles%\Nsudo\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait schtasks /Delete /TN "Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" /F >nul 2>&1
 "%ProgramFiles%\Nsudo\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait schtasks /Delete /TN "Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /F >nul 2>&1
 "%ProgramFiles%\Nsudo\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait schtasks /Delete /TN "Microsoft\Windows\UpdateOrchestrator\Schedule Work" /F >nul 2>&1
)
schtasks /Delete /TN "Microsoft\Windows\WindowsUpdate\Automatic App Update" /F >nul 2>&1
schtasks /Delete /TN "Microsoft\Windows\WindowsUpdate\Scheduled Start" /F >nul 2>&1
schtasks /Delete /TN "Microsoft\Windows\WindowsUpdate\sihboot" /F >nul 2>&1
ECHO.
ECHO Windows Update is now DISABLED.
ECHO.
PAUSE

:end
exit
