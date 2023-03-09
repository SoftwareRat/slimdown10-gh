@echo off
TITLE Windows 10 22H2 slim down and integrate updates
CLS

::
:: Author: Wojciech Keller
:: Version: 1.24
:: License: free
::

:: ============================================================================================================
:: -------------- Start of Configuration Section --------------------------------------------------------------
:: ============================================================================================================

:: Download and integrate updates up to February 2023
 set IntegrateUpdates=1

  :: - Set default NTP time server instead of time.windows.com
   set NTPserver=pool.ntp.org

  :: - Disable time sync service entirely, regardless of the setting above.
  ::   It is recommended to disable it when you want to set your date/time manually or using third party TimeSync software.
   set DisableTimeSync=0

  :: - Disable search indexing. Search will still be fully functional, but with no index being built in the background.
  ::   It is recommended to disable it on systems installed on hard drives or other low resource computers.
   set DisableSearchIndexing=1

  :: - Disable Windows Search service entirely.
  ::   Windows Search on task bar will search now only applications, but no longer documents and files.
  ::   Search in Explorer will search files as usual, but those files will never be indexed.
  ::   It is recommended to disable it on systems installed on hard drives or other low resource computers.
   set DisableSearchService=1

  :: - Disable automatic update of root certificates that used for encrypted connections.
  ::   Internet Explorer and most third party software will complain on every encrypted connection (including entering Google) if this setting is on.
  ::   However Firefox and Chrome have their own root certificate stores so the setting should have no impact on them.
  ::   Nevertheless, it is recommended to keep automatic root certifcates update ENABLED unless they will be updated manually or otherwise in your organization.
  ::   So leave it with setting 0 unless you have good reason to change.
   set DisableRootCertUpdate=0

  ::  - Disable download device drivers and data from Microsoft
  ::    They will have to be installed manually or the functionality can be reanabled later.
   set DisableDriversFromWU=0

  ::  - Disable automatic connecting
  ::    Otherwise Windows connects to http://www.msftconnecttest.com/connecttest.txt to check Internet connection
   set DisableInternetConnectionChecking=0

  ::  - Disable Prefetch and Superfetch 
  ::    May be useful for fast SSD drives or for systems with low RAM memory.
   set DisablePrefetcher=0

  :: - 1 = Disable AutoPlay for all devices inlcuding CD/DVD media
  :: - 0 = Enable autoplay for CD/DVD media only, but disable for the rest for security.
  ::       AutoPlay has been one of the main sources of spreading of viruses in the past.
   set DisableCDAutoPlay=1


  :: Disable Windows Defender builtin antivirus
   set DisableDefender=1

  :: Disable Windows Defender MAPS/SpyNet - for better privacy, but with less security
  :: Note: DisableDefender=1 also implies DisableSpyNet=1
   set DisableSpyNet=1


  :: Add support for legacy HLP Help files
   set AddWinHlp=0


:: Split install.wim if its size exceeds 4 GB so it fits to FAT32 pen drive
 set SplitInstallWim=0

:: Create ISO image or leave installer files in DVD folder
 set CreateISO=1


:: ============================================================================================================
:: ------------- End of Configuration Section -----------------------------------------------------------------
:: ============================================================================================================



:: ============================================================================================================


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
 ECHO The script cannot be run from this location!
 ECHO Current location contatins parenthesis in the PATH.
 ECHO.
 ECHO Please copy and run script from Desktop or another directory!
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)

set DISM=
set InternalDISM=0
del /q /f "%~dp0hotfixes\InternalDISM.txt" >nul 2>&1
set "HostArchitecture=x86"
if exist "%WinDir%\SysWOW64" set "HostArchitecture=amd64"

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
set InternalDISM=1
echo used internal DISM>"%~dp0hotfixes\InternalDISM.txt"
:skipInternalDISM


set ISOName=
for /f "delims=" %%i in ('dir /b "%~dp0*.iso" 2^>nul') do (
 echo %%i 2>nul | findstr /r /c:"^Windows10_x[86][46]_[a-zA-Z][a-zA-Z]-[a-zA-Z][a-zA-Z]*\.iso" >nul 2>&1 || set "ISOName=%%i"
)

set InstallWIMfile=
if exist "%~dp0DVD\sources\install.wim" set "InstallWIMfile=%~dp0DVD\sources\install.wim"
if exist "%~dp0DVD\sources\install.esd" set "InstallWIMfile=%~dp0DVD\sources\install.esd"

if "%ISOName%"=="" (
 if "%InstallWIMfile%"=="" (
  ECHO.
  ECHO.
  ECHO ========================================================================
  ECHO ISO/DVD File not found in main script directory!
  ECHO.
  ECHO Please copy Windows 10 22H2 ISO DVD to the same location as Slimdown10
  ECHO ========================================================================
  ECHO.
  PAUSE >NUL
  goto end
 )
)


if not "%ISOName%"=="" (
 ECHO.
 ECHO.
 ECHO ===============================================================================
 ECHO Unpacking ISO/DVD image: "%ISOName%" to DVD directory...
 ECHO ===============================================================================
 ECHO.

 rd /s /q "%~dp0DVD" >nul 2>&1
 mkdir "%~dp0DVD" >nul 2>&1

 "%~dp0tools\%HostArchitecture%\7z.exe" x -y -o"%~dp0DVD" "%~dp0%ISOName%"
)

set InstallWIMfile=
if exist "%~dp0DVD\sources\install.wim" set "InstallWIMfile=%~dp0DVD\sources\install.wim"
if exist "%~dp0DVD\sources\install.esd" set "InstallWIMfile=%~dp0DVD\sources\install.esd"

if "%InstallWIMfile%"=="" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Install.wim/Install.esd not found inside DVD source image!
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)

if not exist "%~dp0DVD\sources\boot.wim" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Boot.wim not found inside DVD source image!
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)

set ImageStart=1
REM Number of Windows 10 editions inside ISO image
for /f "tokens=2 delims=: " %%i in ('start "" /b "%DISM%" /English /Get-WimInfo /WimFile:"%InstallWIMfile%" ^| find /i "Index"') do (set ImageCount=%%i)


REM CPU architecture of Windows 10 ISO
set ImageArchitecture=x64
for /f "tokens=2 delims=: " %%a in ('start "" /b "%DISM%" /English /Get-WimInfo /WimFile:"%InstallWIMfile%" /Index:%ImageStart% ^| find /i "Architecture"') do (set ImageArchitecture=%%a)
set PackagesArchitecture=amd64
if "%ImageArchitecture%"=="x86" set PackagesArchitecture=x86

REM Language of Windows 10 ISO
set ImageLanguage=en-US
for /f "tokens=1 delims= " %%a in ('start "" /b "%DISM%" /English /Get-WimInfo /WimFile:"%InstallWIMfile%" /Index:%ImageStart% ^| find /i "(Default)"') do (set ImageLanguage=%%a)
for /f "tokens=1 delims= " %%a in ('echo %ImageLanguage%') do (set ImageLanguage=%%a)

REM Check Windows images
set checkErrors=1
if "%ImageArchitecture%"=="x86" set checkErrors=0
if "%ImageArchitecture%"=="x64" set checkErrors=0
for /L %%i in (%ImageStart%, 1, %ImageCount%) do (
 "%DISM%" /English /Get-WimInfo /WimFile:"%InstallWIMfile%" /Index:%%i | findstr /l /i /c:"Architecture" | findstr /l /i /c:"%ImageArchitecture%" >nul 2>&1 || set checkErrors=1
 "%DISM%" /English /Get-WimInfo /WimFile:"%InstallWIMfile%" /Index:%%i | findstr /l /i /c:"Name :" | findstr /l /i /c:"Windows 10" >nul 2>&1 || set checkErrors=1
 "%DISM%" /English /Get-WimInfo /WimFile:"%InstallWIMfile%" /Index:%%i | findstr /l /i /c:"(Default)" | findstr /l /i /c:"%ImageLanguage%" >nul 2>&1 || set checkErrors=1
)

if not "%checkErrors%"=="0" (
 ECHO.
 ECHO.
 ECHO ==========================================================================
 ECHO This script supports only original Windows 10 images for x86 or x64 CPUs!
 ECHO.
 ECHO Mixed images with multiple OSes, multiple langauges
 ECHO or multiple architectures are not supported!
 ECHO ==========================================================================
 ECHO.
 PAUSE >NUL
 goto end
)

setlocal EnableDelayedExpansion
ECHO.
ECHO.
ECHO ================================================================
ECHO Found the following images in ISO/DVD:
ECHO.
set ImageIndexes=
set IoTEnterpriseIndex=
for /L %%i in (%ImageStart%, 1, %ImageCount%) do (
 if %%i GEQ 1 if %%i LSS 10 set "ImageIndexes=!ImageIndexes!%%i"
 if %%i EQU 10 set "ImageIndexes=!ImageIndexes!0"
 if %%i EQU 11 set "ImageIndexes=!ImageIndexes!a"
 if %%i EQU 12 set "ImageIndexes=!ImageIndexes!b"
 ECHO.
 ECHO Index: %%i
 "%DISM%" /English /Get-WimInfo /WimFile:"%InstallWIMfile%" /Index:%%i | find /i "Name :"
 ECHO Architecture: %ImageArchitecture%
 ECHO Language: %ImageLanguage%
 set WimInfoOutput=
 for /f "tokens=1,2 delims=:" %%a in ('"%DISM%" /English /Get-WimInfo /WimFile:"%InstallWIMfile%" /Index:%%i ^| find /i "Name :"') do (
   set WimInfoOutput=%%b
 )
 if "!WimInfoOutput!"==" Windows 10 IoT Enterprise " set "IoTEnterpriseIndex=%%i"
)
ECHO.
ECHO ================================================================
ECHO.
setlocal DisableDelayedExpansion


if not defined IoTEnterpriseIndex (
  ECHO.
  ECHO.
  ECHO ================================================================
  ECHO Windows 10 IoT Enterprise image not found in ISO/DVD!
  ECHO.
  ECHO Please check the ISO/DVD contents and try again.
  ECHO ================================================================
  ECHO.
  PAUSE >NUL
  goto end
)

set ImageIndex=%IoTEnterpriseIndex%

ECHO Selected image index: %ImageIndex%
ECHO.
ECHO.
"%DISM%" /English /Export-Image /SourceImageFile:"%InstallWIMfile%" /SourceIndex:%ImageIndex% /DestinationImageFile:"%~dp0DVD\sources\install_index_%ImageIndex%.wim" /Compress:None /CheckIntegrity
del /q /f "%InstallWIMfile%" >nul 2>&1
move /y "%~dp0DVD\sources\install_index_%ImageIndex%.wim" "%~dp0DVD\sources\install.wim" >nul 2>&1
set InstallWIMfile=
ECHO.

REM Detect H265 codec package
set H265AppxPackage=
for /f "tokens=1 delims=" %%a in ('dir /b "%~dp0hotfixes\H265\*HEVC*%ImageArchitecture%*.appx" 2^>nul') do (set "H265AppxPackage=%%a")

REM Copy additional scripts to DVD for manual run
xcopy "%~dp0ExtraScripts\*" "%~dp0DVD\ExtraScripts\" /e /s /y >nul 2>&1

ECHO.
ECHO.
ECHO ================================================================
ECHO Mounting image with index 1
ECHO Mount directory: %~dp0mount
"%DISM%" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" /Index:1 | find /i "Name :"
ECHO ================================================================
ECHO.

rd /s/q "%~dp0mount" >NUL 2>&1
mkdir "%~dp0mount" >NUL 2>&1
"%DISM%" /English /Mount-Wim /WimFile:"%~dp0DVD\sources\install.wim" /index:1 /MountDir:"%~dp0mount"

if exist "%~dp0mount\Windows\System32\winver.exe" goto mountedCorrectly
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Mounting install.wim failed!
 ECHO.
 ECHO Please run UnmountCleanUp.cmd and try again.
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
:mountedCorrectly

mkdir "%~dp0mount\Windows\Setup\Scripts" >nul 2>&1
mkdir "%~dp0DVD\Updates" >nul 2>&1
echo Please, do not delete.>"%~dp0DVD\Updates\Win10MarkerFile.txt"
echo This is a marker file, needed for SetupComplete.cmd to find this folder.>>"%~dp0DVD\Updates\Win10MarkerFile.txt"

echo @ECHO OFF>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo set CDROM=>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo FOR %%%%I IN (C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST "%%%%I:\Updates\Win10MarkerFile.txt" SET CDROM=%%%%I:>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"

if "%H265AppxPackage%"=="" goto skipH265fromSetupComplete
if "%InternalDISM%"=="0" goto skipH265fromSetupComplete
 echo if "%%CDROM%%"=="" goto skipH265>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
 echo dism /Online /Add-ProvisionedAppxPackage /PackagePath:"%%CDROM%%\Updates\%H265AppxPackage%" /SkipLicense>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
 echo :skipH265>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
:skipH265fromSetupComplete

if not exist "%~dp0hotfixes\directx_Jun2010_redist.exe" goto skipDX9int
 echo if "%%CDROM%%"=="" goto skipDX9>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
 echo start /w "" "%%CDROM%%\Updates\DX9\DXSETUP.exe" /silent>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
 echo :skipDX9>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"

 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Adding DirectX 9 June 2010 to ISO/DVD....
 ECHO ================================================================
 ECHO.
 ECHO.
 start /w "" "%~dp0hotfixes\directx_Jun2010_redist.exe" /t:"%~dp0DVD\Updates\DX9" /c /q
:skipDX9int

echo set CDROM=>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"


if "%IntegrateUpdates%"=="0" goto skipUpdates

ECHO.
ECHO.
ECHO ================================================================
ECHO Downloading missing Windows 10 22H2 Updates...
ECHO ================================================================
ECHO.


type "%~dp0hotfixes\hfixes_all.txt" | find /i "%ImageArchitecture%" > "%~dp0hotfixes\hfixes_%ImageArchitecture%.txt"
cd /d "%~dp0hotfixes"
FOR /F "eol=; tokens=1,2*" %%i in (hfixes_%ImageArchitecture%.txt) do if not exist "%~dp0hotfixes\%%i" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "%%i" "%%j"

REM Restore Title Bar changed by wget
TITLE Windows 10 22H2 slim down and integrate updates

cd /d "%~dp0"
del /q /f "%~dp0hotfixes\hfixes_%ImageArchitecture%.txt" >nul 2>&1

ECHO.
ECHO Done.
ECHO.

ECHO.
ECHO.
ECHO ================================================================
ECHO Integrating main updates to operating system...
ECHO ================================================================
ECHO.


ECHO.
ECHO.
ECHO ================================================================================
ECHO Adding package KB5012170 - Security update for Secure Boot DBX...
ECHO ================================================================================
ECHO.
"%DISM%" /English /Add-Package /Image:"%~dp0mount" /PackagePath:"%~dp0hotfixes\windows10.0-kb5012170-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================================
ECHO Adding package KB5022834 - February 2023 Cumulative...
ECHO ================================================================================
ECHO.
"%DISM%" /English /Add-Package /Image:"%~dp0mount" /PackagePath:"%~dp0hotfixes\windows10.0-kb5022834-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================================
ECHO Adding package KB5022502 - Cumulative Update for .NET Framework 3.5 and 4.8...
ECHO ================================================================================
ECHO.
"%DISM%" /English /Add-Package /Image:"%~dp0mount" /PackagePath:"%~dp0hotfixes\windows10.0-kb5022502-%ImageArchitecture%-ndp48.msu"

:skipUpdates


ECHO.
ECHO.
ECHO =====================================================================================================
ECHO Removing capabilities...
ECHO =====================================================================================================
ECHO.
ECHO.

set "RemoveCapabilities=App.StepsRecorder,App.Support.QuickAssist,Hello.Face,OneCoreUAP.OneSync"

for %%p in (%RemoveCapabilities%) do (
 for /f "tokens=3 delims=: " %%a in ('start "" /b "%DISM%" /English /Image:"%~dp0mount" /Get-Capabilities ^| find "Capability Identity" ^| find "%%p"') do (
   ECHO.
   ECHO.
   ECHO ==================================================================================
   ECHO Removing capability: %%a
   ECHO ==================================================================================
   ECHO.
   %DISM% /English /Image:"%~dp0mount" /Remove-Capability /CapabilityName:"%%a"
  )
)




:: ============================================================================================================
:: -------------- Start of Tweaks Section ---------------------------------------------------------------------
:: ============================================================================================================


:: Disable the following services by default
:: Some services are also added to the list below in their appropriate subsections, eg. Windows Defender, File History etc.
set "DisableServices=AJRouter"
set "DisableServices=%DisableServices%,BcastDVRUserService"
set "DisableServices=%DisableServices%,cbdhsvc"
set "DisableServices=%DisableServices%,diagnosticshub.standardcollector.service"
set "DisableServices=%DisableServices%,diagsvc"
set "DisableServices=%DisableServices%,DiagTrack"
set "DisableServices=%DisableServices%,dmwappushservice"
set "DisableServices=%DisableServices%,DoSvc"
set "DisableServices=%DisableServices%,DPS"
set "DisableServices=%DisableServices%,MessagingService"
set "DisableServices=%DisableServices%,NcdAutoSetup"
set "DisableServices=%DisableServices%,OneSyncSvc"
set "DisableServices=%DisableServices%,PimIndexMaintenanceSvc"
set "DisableServices=%DisableServices%,PushToInstall"
set "DisableServices=%DisableServices%,RetailDemo"
set "DisableServices=%DisableServices%,SgrmBroker"
set "DisableServices=%DisableServices%,shpamsvc"
set "DisableServices=%DisableServices%,SmsRouter"
set "DisableServices=%DisableServices%,SSDPSRV"
set "DisableServices=%DisableServices%,UnistoreSvc"
set "DisableServices=%DisableServices%,upnphost"
set "DisableServices=%DisableServices%,UserDataSvc"
set "DisableServices=%DisableServices%,UsoSvc"
set "DisableServices=%DisableServices%,WaaSMedicSvc"
set "DisableServices=%DisableServices%,WalletService"
set "DisableServices=%DisableServices%,WdiServiceHost"
set "DisableServices=%DisableServices%,WdiSystemHost"
set "DisableServices=%DisableServices%,wercplsupport"
set "DisableServices=%DisableServices%,WerSvc"
set "DisableServices=%DisableServices%,wisvc"
set "DisableServices=%DisableServices%,wlidsvc"
set "DisableServices=%DisableServices%,WMPNetworkSvc"
set "DisableServices=%DisableServices%,WpnService"
set "DisableServices=%DisableServices%,XblAuthManager"
set "DisableServices=%DisableServices%,XblGameSave"
set "DisableServices=%DisableServices%,XboxNetApiSvc"

:: Remove the following tasks by default
:: Some tasks are also added to the list below in their appropriate subsections, eg. Windows Defender, File History etc.
set RemoveTasks="Application Experience\AitAgent","Application Experience\Microsoft Compatibility Appraiser","Application Experience\ProgramDataUpdater","Application Experience\StartupAppTask"
set RemoveTasks=%RemoveTasks%,"AppListBackup\Backup"
set RemoveTasks=%RemoveTasks%,"Autochk\Proxy"
set RemoveTasks=%RemoveTasks%,"BrokerInfrastructure\BgTaskRegistrationMaintenanceTask"
set RemoveTasks=%RemoveTasks%,"Chkdsk\ProactiveScan","Chkdsk\SyspartRepair"
set RemoveTasks=%RemoveTasks%,"Customer Experience Improvement Program\Consolidator","Customer Experience Improvement Program\KernelCeipTask","Customer Experience Improvement Program\UsbCeip"
set RemoveTasks=%RemoveTasks%,"Defrag\ScheduledDefrag"
set RemoveTasks=%RemoveTasks%,"Device Information\Device","Device Information\Device User"
set RemoveTasks=%RemoveTasks%,"DeviceDirectoryClient\HandleCommand","DeviceDirectoryClient\HandleWnsCommand","DeviceDirectoryClient\IntegrityCheck","DeviceDirectoryClient\LocateCommandUserSession","DeviceDirectoryClient\RegisterDeviceAccountChange","DeviceDirectoryClient\RegisterDeviceLocationRightsChange","DeviceDirectoryClient\RegisterDevicePeriodic24","DeviceDirectoryClient\RegisterDevicePolicyChange","DeviceDirectoryClient\RegisterDeviceProtectionStateChanged","DeviceDirectoryClient\RegisterDeviceSettingChange","DeviceDirectoryClient\RegisterUserDevice"
set RemoveTasks=%RemoveTasks%,"Diagnosis\RecommendedTroubleshootingScanner","Diagnosis\Scheduled"
set RemoveTasks=%RemoveTasks%,"DiskCleanup\SilentCleanup"
set RemoveTasks=%RemoveTasks%,"DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
set RemoveTasks=%RemoveTasks%,"DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
set RemoveTasks=%RemoveTasks%,"DiskFootprint\Diagnostics"
set RemoveTasks=%RemoveTasks%,"DiskFootprint\Diagnostics"
set RemoveTasks=%RemoveTasks%,"DUSM\dusmtask"
set RemoveTasks=%RemoveTasks%,"Feedback\Siuf\DmClient","Feedback\Siuf\DmClientOnScenarioDownload"
set RemoveTasks=%RemoveTasks%,"Flighting\FeatureConfig\ReconcileFeatures","Flighting\FeatureConfig\UsageDataFlushing","Flighting\FeatureConfig\UsageDataReporting","Flighting\OneSettings\RefreshCache"
set RemoveTasks=%RemoveTasks%,"HelloFace\FODCleanupTask"
set RemoveTasks=%RemoveTasks%,"Input\LocalUserSyncDataAvailable","Input\MouseSyncDataAvailable","Input\PenSyncDataAvailable","Input\TouchpadSyncDataAvailable"
set RemoveTasks=%RemoveTasks%,"InstallService\ScanForUpdates","InstallService\ScanForUpdatesAsUser","InstallService\SmartRetry","InstallService\WakeUpAndContinueUpdates","InstallService\WakeUpAndScanForUpdates"
set RemoveTasks=%RemoveTasks%,"International\Synchronize Language Settings"
set RemoveTasks=%RemoveTasks%,"Maintenance\WinSAT"
set RemoveTasks=%RemoveTasks%,"Management\Autopilot\DetectHardwareChange","Management\Autopilot\RemediateHardwareChange"
set RemoveTasks=%RemoveTasks%,"Management\Provisioning\Cellular","Management\Provisioning\Logon","Management\Provisioning\PostResetBoot","Management\Provisioning\Retry","Management\Provisioning\RunOnReboot"
set RemoveTasks=%RemoveTasks%,"Maps\MapsToastTask","Maps\MapsUpdateTask"
set RemoveTasks=%RemoveTasks%,"MemoryDiagnostic\ProcessMemoryDiagnosticEvents","MemoryDiagnostic\RunFullMemoryDiagnostic"
set RemoveTasks=%RemoveTasks%,"Mobile Broadband Accounts\MNO Metadata Parser"
set RemoveTasks=%RemoveTasks%,"NetTrace\GatherNetworkInfo"
set RemoveTasks=%RemoveTasks%,"NlaSvc\WiFiTask"
set RemoveTasks=%RemoveTasks%,"PI\Sqm-Tasks"
set RemoveTasks=%RemoveTasks%,"Power Efficiency Diagnostics\AnalyzeSystem"
set RemoveTasks=%RemoveTasks%,"PushToInstall\LoginCheck","PushToInstall\Registration"
set RemoveTasks=%RemoveTasks%,"RecoveryEnvironment\VerifyWinRE"
set RemoveTasks=%RemoveTasks%,"SettingSync\BackgroundUploadTask","SettingSync\BackupTask","SettingSync\NetworkStateChangeTask"
set RemoveTasks=%RemoveTasks%,"Shell\FamilySafetyMonitor","Shell\FamilySafetyRefresh","Shell\FamilySafetyRefreshTask","Shell\ThemesSyncedImageDownload","Shell\UpdateUserPictureTask"
set RemoveTasks=%RemoveTasks%,"UNP\RunUpdateNotificationMgr"
set RemoveTasks=%RemoveTasks%,"Speech\SpeechModelDownloadTask"
set RemoveTasks=%RemoveTasks%,"UpdateOrchestrator\Report policies","UpdateOrchestrator\Schedule Scan Static Task","UpdateOrchestrator\UpdateModelTask","UpdateOrchestrator\USO_UxBroker"
set RemoveTasks=%RemoveTasks%,"UPnP\UPnPHostConfig"
set RemoveTasks=%RemoveTasks%,"WaaSMedic\PerformRemediation"
set RemoveTasks=%RemoveTasks%,"WCM\WiFiTask"
set RemoveTasks=%RemoveTasks%,"WDI\ResolutionHost"
set RemoveTasks=%RemoveTasks%,"Windows Error Reporting\QueueReporting"
set RemoveTasks=%RemoveTasks%,"Windows Media Sharing\UpdateLibrary"
set RemoveTasks=%RemoveTasks%,"WindowsUpdate\Automatic App Update","WindowsUpdate\Scheduled Start","WindowsUpdate\sihboot"
set RemoveTasks=%RemoveTasks%,"WlanSvc\CDSSync"
set RemoveTasks=%RemoveTasks%,"WwanSvc\NotificationTask"
set RemoveTasks=%RemoveTasks%,"WwanSvc\OobeDiscovery"


:: Disable the following trackers/loggers
:: Some trackers are also added to the list below in their appropriate subsections, eg. Windows Defender
set DisableTrackers="AutoLogger-Diagtrack-Listener","Circular Kernel Context Logger","DiagLog","Diagtrack-Listener","LwtNetLog","Microsoft-Windows-Rdp-Graphics-RdpIdd-Trace","NetCore","NtfsLog","RadioMgr","ReadyBoot","SQMLogger","UBPM","WdiContextLog","WiFiSession"



:: All user UWP applications listed in \Program Files\WindowsApps will be removed with the exception of the following list
:: In other words: It is the list of UWP apps that you want to keep.
set "IncludeUWPapps=Microsoft.VCLibs,Microsoft.NET.Native,Microsoft.HEIFImageExtension,Microsoft.VP9VideoExtensions,Microsoft.WebMediaExtensions,Microsoft.WebpImageExtension"


:: Disable these permisions for system UWP apps
:: eg. if you want to prevent system UWP apps from accessing cellular data, WiFi data, microphone and camera
:: replace the following line with   set DisableSysUWPpermissions=cellularData,wifiData,microphone,webcam
set DisableSysUWPpermissions=

:: By default disable most permisions for UWP apps
set DisableUWPpermissions=activity,appDiagnostics,appointments,bluetooth,bluetoothSync,cellularData,chat,contacts,email,gazeInput,location,microphone,phoneCall,phoneCallHistory,radios,sensors.custom,serialCommunication,usb,userAccountInformation,userDataTasks,userNotificationListener,webcam,wifiData,wiFiDirect

::  By default remove all system UWP apps unless they are really necessary
::  Can be changed to minimal version  set "RemoveSystemUWPapps=Microsoft.MicrosoftEdge,Microsoft.MicrosoftEdgeDevToolsClient,Microsoft.Windows.ContentDeliveryManager"
set "RemoveSystemUWPapps=Microsoft.AccountsControl,Microsoft.AsyncTextService,Microsoft.BioEnrollment,microsoft.creddialoghost,Microsoft.ECApp,Microsoft.LockApp,Microsoft.MicrosoftEdge,Microsoft.MicrosoftEdgeDevToolsClient,Microsoft.Windows.AddSuggestedFoldersToLibraryDialog,Microsoft.Windows.AppRep.ChxApp,Microsoft.Windows.AppResolverUX,Microsoft.Windows.AssignedAccessLockApp,Microsoft.Windows.CallingShellApp,Microsoft.Windows.CapturePicker,Microsoft.Windows.ContentDeliveryManager,microsoft.windows.narratorquickstart,Microsoft.Windows.OOBENetworkCaptivePortal,Microsoft.Windows.OOBENetworkConnectionFlow,Microsoft.Windows.PeopleExperienceHost,Microsoft.Windows.PinningConfirmationDialog,Microsoft.Windows.SecureAssessmentBrowser,Microsoft.XboxGameCallableUI,MicrosoftWindows.Client.CBS,MicrosoftWindows.UndockedDevKit,NcsiUwpApp,ParentalControls,Windows.CBSPreview"

::  By default UWP apps are only removed from the Registry, leaving files on the disk
::  thus possibly preventing their reinstallations by futere Windows updates.
::  This setting causes system UWP apps to be also removed from the disk.
set RemoveSystemUWPappsAlsoFromDisk=0




REM Internal DISM does not support provisioned packages servicing
if "%InternalDISM%"=="1" goto skipDISMprov

ECHO.
ECHO.
ECHO =====================================================================================================
ECHO Adding/Removing provisioned packages...
ECHO =====================================================================================================
ECHO.
ECHO.

setlocal EnableDelayedExpansion
for /f "tokens=2 delims=: " %%a in ('start "" /b "%DISM%" /English /Image:"%~dp0mount" /Get-ProvisionedAppxPackages ^| find "PackageName"') do (
 set "RemoveUWPapp=%%a"
 for %%u in (%IncludeUWPapps%) do (
  echo %%a | findstr /l /i /c:"%%u" >nul 2>&1 && set RemoveUWPapp=
 )

 if not "!RemoveUWPapp!"=="" (
  ECHO.
  ECHO.
  ECHO =====================================================================================================
  ECHO Removing provisioned package: !RemoveUWPapp!
  ECHO =====================================================================================================
  ECHO.
  "%DISM%" /English /Image:"%~dp0mount" /Remove-ProvisionedAppxPackage /PackageName:"!RemoveUWPapp!"
 )
)
setlocal DisableDelayedExpansion

if "%H265AppxPackage%"=="" goto skipDISMprov
if not exist "%~dp0hotfixes\H265\%H265AppxPackage%" goto skipDISMprov
ECHO.
ECHO.
ECHO =====================================================================================================
ECHO Adding provisioned package: %H265AppxPackage%
ECHO =====================================================================================================
ECHO.
"%DISM%" /English /Image:"%~dp0mount" /Add-ProvisionedAppxPackage /PackagePath:"%~dp0hotfixes\H265\%H265AppxPackage%" /SkipLicense

:skipDISMprov


ECHO.
ECHO.
ECHO ================================================================================
ECHO Cleaning up the WinSxS Folder
ECHO ================================================================================
ECHO.
%DISM% /English /Image:"%~dp0mount" /Cleanup-Image /StartComponentCleanup /ResetBase

if not exist "%~dp0DVD\sources\sxs\microsoft-windows-netfx3-*" goto skipNETFXup
ECHO.
ECHO.
ECHO ================================================================================
ECHO Adding support for .NET Framework 3.5 for older applications...
ECHO ================================================================================
ECHO.
%DISM% /English /Image:"%~dp0mount" /Add-Capability /CapabilityName:"NetFX3~~~~" /Source:"%~dp0DVD\sources\sxs"

if "%IntegrateUpdates%"=="0" goto skipNETFXup
ECHO.
ECHO.
ECHO ================================================================================
ECHO Re-applying package KB5022834 - February 2023 Cumulative...
ECHO ================================================================================
ECHO.
"%DISM%" /English /Add-Package /Image:"%~dp0mount" /PackagePath:"%~dp0hotfixes\windows10.0-kb5022834-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================================
ECHO Re-applying package KB5022502 - Cumulative Update for .NET Framework 3.5 and 4.8...
ECHO ================================================================================
ECHO.
"%DISM%" /English /Add-Package /Image:"%~dp0mount" /PackagePath:"%~dp0hotfixes\windows10.0-kb5022502-%ImageArchitecture%-ndp48.msu"
:skipNETFXup

echo.
echo.
ECHO =====================================
echo Mounting registry
ECHO =====================================
echo.

REM Be sure that it is clean before mounting
reg unload HKLM\TK_DEFAULT >nul 2>&1
reg unload HKLM\TK_NTUSER >nul 2>&1
reg unload HKLM\TK_SOFTWARE >nul 2>&1
reg unload HKLM\TK_SYSTEM >nul 2>&1
REM Mount registry hives
reg load HKLM\TK_DEFAULT "%~dp0mount\Windows\System32\config\default" >nul
reg load HKLM\TK_NTUSER "%~dp0mount\Users\Default\ntuser.dat" >nul
reg load HKLM\TK_SOFTWARE "%~dp0mount\Windows\System32\config\SOFTWARE" >nul
reg load HKLM\TK_SYSTEM "%~dp0mount\Windows\System32\config\SYSTEM" >nul


REM This section is only for compatibility with Windows 7/8/8.1
if "%InternalDISM%"=="0" goto skipREGprov

ECHO.
ECHO.
ECHO =====================================================================================================
ECHO Removing provisioned packages...
ECHO =====================================================================================================
ECHO.
ECHO.

if not "%H265AppxPackage%"=="" copy /b /y "%~dp0hotfixes\H265\%H265AppxPackage%" "%~dp0DVD\Updates" >nul 2>&1

setlocal EnableDelayedExpansion
for /f "tokens=1 delims=" %%a in ('dir /on /b "%~dp0mount\Program Files\WindowsApps\Microsoft.*" 2^>nul') do (
 set "RemoveUWPapp=%%a"
 for %%u in (%IncludeUWPapps%) do (
  echo %%a | findstr /l /i /c:"%%u" >nul 2>&1 && set RemoveUWPapp=
 )

 if not "!RemoveUWPapp!"=="" (
  ECHO.
  ECHO.
  ECHO =====================================================================================================
  ECHO Removing provisioned package from Disk: !RemoveUWPapp!
  ECHO =====================================================================================================
  ECHO.
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait cmd /c "rd /s /q "%~dp0mount\Program Files\WindowsApps\!RemoveUWPapp!""
 )
)

REM Clear the registry keys too
for /f "tokens=9 delims=\" %%a in ('reg query "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications" /k /f "Microsoft." 2^>nul ^| find /i "\Applications\Microsoft."') do (
 set "RemoveUWPapp=%%a"
 for %%u in (%IncludeUWPapps%) do (
  echo %%a | findstr /l /i /c:"%%u" >nul 2>&1 && set RemoveUWPapp=
 )

 if not "!RemoveUWPapp!"=="" (
  ECHO.
  ECHO.
  ECHO =====================================================================================================
  ECHO Removing provisioned package from the Registry: !RemoveUWPapp!
  ECHO =====================================================================================================
  ECHO.
  reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications\!RemoveUWPapp!" /f >nul 2>&1
   for /f "tokens=1,4,5 delims=_" %%b in ('echo !RemoveUWPapp!') do (
    if "%%d"=="" (
     reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\%%b_%%c" /f >nul
     reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\%%b_%%c" /ve /f >nul 2>&1
     reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Staged\%%b_%%c" /f >nul 2>&1
     reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config\%%b_%%c" /f >nul 2>&1
    )
    if not "%%d"=="" (
     reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\%%b_%%d" /f >nul
     reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\%%b_%%d" /ve /f >nul 2>&1
     reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Staged\%%b_%%d" /f >nul 2>&1
     reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config\%%b_%%d" /f >nul 2>&1
    )
   )
 )
)
setlocal DisableDelayedExpansion
:skipREGprov

set InternalDISM=


ECHO.
ECHO.
ECHO ========================================
echo Applying settings...
ECHO ========================================
ECHO.

REM Disable App Compatibility Assistant
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f >nul
set "DisableServices=%DisableServices%,AeLookupSvc,PcaSvc"

 
REM Disable and Remove Telemetry and Spying
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\SQM" /v "DisableCustomerImprovementProgram" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting" /v "DoReport" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d 1 /f >nul
REM AllowTelemetry = 1 means basic telemetry, 3 means full telemetry, 0 is inaccessible in non-enterprise Windows editions
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 1 /f > NUL
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d 0 /f > NUL
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDesktopAnalyticsProcessing" /t REG_DWORD /d 0 /f > NUL
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowCommercialDataPipeline" /t REG_DWORD /d 0 /f > NUL
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowUpdateComplianceProcessing" /t REG_DWORD /d 0 /f > NUL
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowWUfBCloudProcessing" /t REG_DWORD /d 0 /f > NUL
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f > NUL
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DisableOneSettingsDownloads" /t REG_DWORD /d 1 /f > NUL
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v "AllowBuildPreview" /t REG_DWORD /d 0 /f > NUL

REM Disable Troubleshooting and Diagnostics
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{186f47ef-626c-4670-800a-4a30756babad}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{2698178D-FDAD-40AE-9D3C-1371703ADC5B}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{29689E29-2CE9-4751-B4FC-8EFF5066E3FD}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{29689E29-2CE9-4751-B4FC-8EFF5066E3FD}" /v "EnabledScenarioExecutionLevel" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{3af8b24a-c441-4fa4-8c5c-bed591bfa867}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{54077489-683b-4762-86c8-02cf87a33423}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{67144949-5132-4859-8036-a737b43825d8}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{8519d925-541e-4a2b-8b1e-8059d16082f2}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{86432a0b-3c7d-4ddf-a89c-172faa90485d}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{a7a5847a-7511-4e4e-90b1-45ad2a002f51}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{C295FBBA-FD47-46ac-8BEE-B1715EC634E5}" /v "DownloadToolsEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{C295FBBA-FD47-46ac-8BEE-B1715EC634E5}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{dc42ff48-e40d-4a60-8675-e71f7e64aa9a}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{dc42ff48-e40d-4a60-8675-e71f7e64aa9a}" /v "EnabledScenarioExecutionLevel" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{eb73b633-3f4e-4ba0-8f60-8f3c6f53168f}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{eb73b633-3f4e-4ba0-8f60-8f3c6f53168f}" /v "EnabledScenarioExecutionLevel" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{ecfb03d1-58ee-4cc7-a1b5-9bc6febcb915}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WDI\{ffc42108-4920-4acf-a4fc-8abdcc68ada4}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f >nul


REM Disable Cloud Content
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\PushToInstall" /v "DisablePushToInstall" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableSoftLanding" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableThirdPartySuggestions" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "ConfigureWindowsSpotlight" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "IncludeEnterpriseSpotlight" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightWindowsWelcomeExperience" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnActionCenter" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnSettings" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SlideshowEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310091Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310092Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310094Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314558Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314559Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314562Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314563Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314566Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-314567Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338380Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338381Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338382Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338386Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338394Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338396Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-346480Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-346481Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353695Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353697Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353698Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353699Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000044Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000045Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000105Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000106Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000161Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000162Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000163Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000164Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000165Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul


REM Setup Complete Script, Uninstall Edge, Disable NTFS last access time updates, re-apply power settings
echo fsutil behavior set disableLastAccess ^1 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
REM Re-apply disable hibernation
echo powercfg /h off ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
REM Re-apply disable USB AutoSuspend
echo powercfg /SETDCVALUEINDEX 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo powercfg /SETACVALUEINDEX 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo powercfg /SETDCVALUEINDEX 381b4222-f694-41f0-9685-ff5bb260df2e 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo powercfg /SETACVALUEINDEX 381b4222-f694-41f0-9685-ff5bb260df2e 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
REM Re-apply disable idle Hard Disk auto power off
echo powercfg /SETDCVALUEINDEX 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo powercfg /SETACVALUEINDEX 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo powercfg /SETDCVALUEINDEX 381b4222-f694-41f0-9685-ff5bb260df2e 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo powercfg /SETACVALUEINDEX 381b4222-f694-41f0-9685-ff5bb260df2e 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo set "PF=%%ProgramFiles%%">>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo if not "%%ProgramFiles(x86)%%"=="" set "PF=%%ProgramFiles(x86)%%">>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo set EdgeSetup=>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo for /f "delims=" %%%%i in ('dir /b /s /a-d "%%PF%%\Microsoft\Edge\Application\setup.exe" 2^^^>nul') do (set "EdgeSetup=%%%%i")>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo if "%%EdgeSetup%%"=="" goto skipEdgeUinstall>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo start /w "" "%%EdgeSetup%%" --uninstall --system-level --force-uninstall>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo reg delete "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo :skipEdgeUinstall>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo set PF=>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo set EdgeSetup=>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
if not "%RemoveSystemUWPappsAlsoFromDisk%"=="0" echo rd /s /q "%%windir%%\SystemApps\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy">>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"
echo del /q /f "%%windir%%\Setup\Scripts\SetupComplete.cmd" ^>nul 2^>^&^1>>"%~dp0mount\Windows\Setup\Scripts\SetupComplete.cmd"

REM User Setup for each new user, re-apply some  settings which otherwise aren't honored when set in default user registry node
echo @ECHO OFF>"%~dp0mount\Windows\UserSetup.cmd"
echo TITLE User settings setup>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d "0" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo schtasks /Delete /TN "Microsoft\Windows\RetailDemo\CleanupOfflineContent" /F ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo del /q /f "%%USERPROFILE%%\Favorites\Bing.url" ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012078010000000 /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg add "HKCU\AppEvents\Schemes" /ve /t REG_SZ /d ".None" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo for /f "tokens=1 delims=" %%%%a in ('reg query "HKCU\AppEvents\Schemes\Apps" 2^^^>nul ^^^| find /i "\Schemes\"') do (>>"%~dp0mount\Windows\UserSetup.cmd"
echo  for /f "tokens=1 delims=" %%%%b in ('reg query "%%%%a" 2^^^>nul ^^^| find /i "%%%%a\"') do (>>"%~dp0mount\Windows\UserSetup.cmd"
echo   for /f "tokens=1 delims=" %%%%c in ('reg query "%%%%b" /e /k /f ".Current" 2^^^>nul ^^^| find /i "%%%%b\.Current"') do (>>"%~dp0mount\Windows\UserSetup.cmd"
echo    reg add "%%%%c" /ve /t REG_SZ /d "" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo   )>>"%~dp0mount\Windows\UserSetup.cmd"
echo  )>>"%~dp0mount\Windows\UserSetup.cmd"
echo )>>"%~dp0mount\Windows\UserSetup.cmd"
echo sc config wlidsvc start= demand ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo sc config DmEnrollmentSvc start= disabled ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo net stop DmEnrollmentSvc /y ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
REM Disable F1 to get help
if "%ImageArchitecture%"=="x86" echo reg add "HKCU\SOFTWARE\Classes\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
if "%ImageArchitecture%"=="x64" echo reg add "HKCU\SOFTWARE\Classes\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg load HKLM\TK_NTUSER "%%SystemDrive%%\Users\Default\ntuser.dat" ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg delete "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Run" /v "UserSetup" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg unload HKLM\TK_NTUSER ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo schtasks /Delete /TN "Microsoft\Windows\WindowsUpdate\Scheduled Start" /F ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "UserSetup" /f ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
echo del /q /f "%%windir%%\UserSetup.cmd" ^>nul 2^>^&^1>>"%~dp0mount\Windows\UserSetup.cmd"
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "UserSetup" /t REG_EXPAND_SZ /d "%%SystemRoot%%\UserSetup.cmd" /f >nul



REM Disable Push Notifications
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoCloudApplicationNotification" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoTileApplicationNotification" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "DisallowNotificationMirroring" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessNotifications" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Deny" /f >nul

REM Use classic notifications
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "EnableLegacyBalloonNotifications" /t REG_DWORD /d 1 /f >nul


REM Disable All Settings Sync
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync" /v "SyncPolicy" /t REG_DWORD /d "5" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\AppSync" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\DesktopTheme" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\PackageState" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\StartLayout" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows" /v "Enabled" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "EnableBackupForWin8Apps" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableAppSyncSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableAppSyncSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableStartLayoutSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableStartLayoutSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSyncOnPaidNetwork" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWebBrowserSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWindowsSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableWindowsSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisablePersonalizationSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisablePersonalizationSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableDesktopThemeSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableDesktopThemeSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableCredentialsSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableCredentialsSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableApplicationSettingSync" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableApplicationSettingSyncUserOverride" /t REG_DWORD /d "1" /f >nul

REM Disable Active Help
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Assistance\Client\1.0" /v "NoActiveHelp" /t REG_DWORD /d "1" /f >nul

REM Search Settings
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /t REG_DWORD /d 0 /f >nul


REM User Privacy Policies
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowCrossDeviceClipboard" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Clipboard" /v "CloudClipboardAutomaticUpload" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Clipboard" /v "EnableCloudClipboard" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" /v "HasAccepted" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Narrator\NoRoam" /v "OnlineServicesEnabled" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Narrator\NoRoam" /v "WinEnterLaunchEnabled" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\InputPersonalization" /v "AllowInputPersonalization" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Personalization\Settings" /v "AcceptedPrivacyPolicy" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput" /v "AllowLinguisticDataCollection" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput" /v "AllowLanguageFeaturesUninstall" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchHistory" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "AllowOnlineTips" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableAppUriHandlers" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\StorageHealth" /v "AllowDiskHealthModelUpdates" /t REG_DWORD /d 0 /f >nul

Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v "PreventHandwritingDataSharing" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" /v "PreventHandwritingErrorReports" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\PCHealth\HelpSvc" /v "Headlines" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoPublishingWizard" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoWebServices" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoOnlinePrintsWizard" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\PCHealth\HelpSvc" /v "MicrosoftKBSearch" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Internet Connection Wizard" /v "ExitOnMSICW" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Registration Wizard Control" /v "NoRegistration" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\SearchCompanion" /v "DisableContentFileUpdates" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d 1 /f >nul
rem Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\EventViewer" /v "MicrosoftEventVwrDisableLinks" /t REG_DWORD /d 1 /f >nul
rem Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "NoGenTicket" /t REG_DWORD /d 1 /f >nul

REM Disable Voice Activation
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationOnLockScreenEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsActivateWithVoice" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsActivateWithVoiceAboveLock" /t REG_DWORD /d 2 /f >nul

REM Disable Background UWP Apps
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy" /v "Disabled" /t REG_DWORD /d 1 /f >nul


REM Privacy Restrictions for UWP apps
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\activity" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\gazeInput" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\activity" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\gazeInput" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsGetDiagnosticInfo" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessAccountInfo" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessMotion" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessGazeInput" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessBackgroundSpatialPerception" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessContacts" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessCalendar" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessCallHistory" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessTasks" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessPhone" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessRadios" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsSyncWithDevices" /t REG_DWORD /d 2 /f >nul
rem Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessTrustedDevices" /t REG_DWORD /d 2 /f >nul


REM Disable Autoupdate Offline Maps Data
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Maps" /v "AutoDownloadAndUpdateMapData" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Maps" /v "AllowUntriggeredNetworkTrafficOnSettingsPage" /t REG_DWORD /d 0 /f >nul


REM Disable UWP Messaging
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessMessaging " /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Messaging" /v "AllowMessageSync" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Messaging" /v "CloudServiceSyncEnabled" /t REG_DWORD /d 0 /f >nul


REM Disable Windows Mail UWP App
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Mail" /v "ManualLaunchAllowed" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessEmail" /t REG_DWORD /d 2 /f >nul


REM Disable Shared Experience
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP\SettingsPage" /v BluetoothLastDisabledNearShare /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" /v NearShareChannelUserAuthzPolicy /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" /v CdpSessionUserAuthzPolicy /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableCdp" /t REG_DWORD /d 0 /f >nul


REM Disable File History
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\FileHistory" /v "Disabled" /t REG_DWORD /d 1 /f >nul
set "DisableServices=%DisableServices%,fhsvc"
set RemoveTasks=%RemoveTasks%,"FileHistory\File History (maintenance mode)"

REM Disbale Home Group
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\HomeGroup" /v "DisableHomeGroup" /t REG_DWORD /d 1 /f >nul

REM Disable Windows Store
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsStore" /v "DisableStoreApps" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsStore" /v "DisableOSUpgrade" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d 2 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d 1 /f >nul


REM Disable System Restore
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v "DisableSR" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v "DisableConfig" /t REG_DWORD /d 1 /f >nul
set RemoveTasks=%RemoveTasks%,"SystemRestore\SR"
reg add "HKLM\TK_SYSTEM\ControlSet001\Services\swprv" /v "Start" /t REG_DWORD /d "3" /f >nul

REM Disable Storage Sense
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseTemporaryFilesCleanup" /t REG_DWORD /d 0 /f >nul
set RemoveTasks=%RemoveTasks%,"DiskFootprint\StorageSense"

REM Disable Offline Files
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\NetCache" /v "Enabled" /t REG_DWORD /d 0 /f >nul
set "DisableServices=%DisableServices%,CSC,CscService"
set RemoveTasks=%RemoveTasks%,"Offline Files\Background Synchronization","Offline Files\Logon Synchronization"


REM Disable Xbox Game Mode
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\GameBar" /v "ShowGameModeNotifications" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f >nul
reg query "HKLM\TK_SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId" /e /k /f "Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" >nul 2>&1 && "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" /v "ActivationType" /t REG_DWORD /d 0 /f >nul
reg query "HKLM\TK_SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId" /e /k /f "Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" >nul 2>&1 && "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" /v "ActivationType" /t REG_DWORD /d 0 /f >nul

REM Remove Xbox Task
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{41F5FC9D-EE65-4CA4-A908-91B3587198E0}" /f >nul 2>&1
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{41F5FC9D-EE65-4CA4-A908-91B3587198E0}" /f >nul 2>&1
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\XblGameSave\XblGameSaveTask" /f >nul 2>&1


REM Disable Windows Search online features
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaInAAD" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaInAADPathOOBE" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWebOverMeteredConnections" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f >nul
 REM For Windows version 1909 or older
 REM Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoRemoteDestinations" /t REG_DWORD /d 1 /f >nul

REM Disable Font Streaming
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableFontProviders" /t REG_DWORD /d 0 /f >nul

REM Disable News and Interests
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarOpenOnHover" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarContentUpdateMode" /t REG_DWORD /d 0 /f >nul

REM Do not notify about new apps or frequently used apps
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoNewAppAlert" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoStartMenuMFUprogramsList" /t REG_DWORD /d 1 /f >nul

REM Hide Map network drive from context menu on This PC
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoNetConnectDisconnect" /t REG_DWORD /d 1 /f >nul

REM Hide Manage verb from context menu on This PC
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoManageMyComputerVerb" /t REG_DWORD /d 1 /f >nul

REM No low disk space warning
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoLowDiskSpaceChecks" /t REG_DWORD /d 1 /f >nul

REM Hide People Bar
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HidePeopleBar" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v "PeopleBand" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v "CapacityOfPeopleBar" /t REG_DWORD /d 0 /f >nul

REM Disable Meet Now
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d 1 /f >nul

REM Disable Microsoft Account and non-password sign-in options
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MicrosoftAccount" /v "DisableUserAuth" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "NoConnectedUser" /t REG_DWORD /d 3 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" /v "value" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowSignInOptions" /v "value" /t REG_DWORD /d 0 /f >nul

REM Disable Windows Hello for Business
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\PassportForWork" /v "Enabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\PassportForWork" /v "DisablePostLogonProvisioning" /t REG_DWORD /d 0 /f >nul

REM Disable and Remove OneDrive
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSync" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableMeteredNetworkFileSync" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableLibrariesDefaultSaveToOneDrive" /t REG_DWORD /d 1 /f >nul
reg delete "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f >nul 2>&1
del /q /f "%~dp0mount\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" >nul 2>&1
if exist "%~dp0mount\Windows\System32\OneDriveSetup.exe" "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait cmd /c "del /q /f "%~dp0mount\Windows\System32\OneDriveSetup.exe"" >nul 2>&1
if exist "%~dp0mount\Windows\SysWOW64\OneDriveSetup.exe" "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait cmd /c "del /q /f "%~dp0mount\Windows\SysWOW64\OneDriveSetup.exe"" >nul 2>&1

REM Disable Location and Sensors
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessLocation" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableSensors" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocationScripting" /t REG_DWORD /d 1 /f >nul
set "DisableServices=%DisableServices%,lfsvc"
set RemoveTasks=%RemoveTasks%,"Location\Notifications","Location\WindowsActionDialog"

REM Disable Find My Device
Reg add "HKLM\TK_SOFTWARE\Microsoft\MdmCommon\SettingValues" /v "LocationSyncEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\FindMyDevice" /v "AllowFindMyDevice" /t REG_DWORD /d 0 /f >nul

REM Disable Action Center
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "UseActionCenterExperience" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAHealth" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoBalloonFeatureAdvertisements" /t REG_DWORD /d 1 /f >nul
rem Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\wscsvc" /v "Start" /t REG_DWORD /d "4" /f >nul
rem "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait cmd /c "del /q /f "%~dp0mount\Windows\SystemApps\ShellExperienceHost_cw5n1h2txyewy\Windows.UI.ActionCenter.dll"" >nul 2>&1

REM Show All TaskBar Icons
Reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "EnableAutoTray" /t REG_DWORD /d 0 /f >nul

REM Disable and pre-remove Edge, SetupComplete.cmd remove the rest
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "PreventLiveTileDataCollection" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d "1" /f >nul
reg delete "HKLM\TK_SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f >nul 2>&1
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg delete "HKLM\TK_SOFTWARE\Microsoft\SystemSettings\SettingId\SystemSettings_AssignedAccess_EdgeAdvancedOptions" /f >nul 2>&1
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg delete "HKLM\TK_SOFTWARE\Microsoft\SystemSettings\SettingId\SystemSettings_AssignedAccess_EdgeKioskMode" /f >nul 2>&1
reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" /f >nul 2>&1
if "%ImageArchitecture%"=="x64" reg delete "HKLM\TK_SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" /f >nul 2>&1
reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications\Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe" /f >nul 2>&1
reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications\Microsoft.MicrosoftEdgeDevToolsClient_10.0.19041.1023_neutral__8wekyb3d8bbwe" /f >nul 2>&1
reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\edgeupdate" /f >nul 2>&1
reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\edgeupdatem" /f >nul 2>&1

REM Disable Internet Explorer to Edge redirection extension
Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}" /f >nul 2>&1
if "%ImageArchitecture%"=="x64" Reg delete "HKLM\TK_SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}" /f >nul 2>&1

REM Disable Operating System Upgrade
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableOSUpgrade" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade" /v "AllowOSUpgrade" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SYSTEM\Setup\UpgradeNotification" /v "UpgradeAvailable" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsStore" /v "DisableOSUpgrade" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ProductVersion" /t REG_SZ /d "Windows 10" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersion" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersionInfo" /t REG_SZ /d "22H2" /f >nul

REM Windows Update Tweaks
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "IncludeRecommendedUpdates" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "EnableFeaturedSoftware" /t REG_DWORD /d "0" /f >nul
if not "%DisableDriversFromWU%"=="0" (
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /v DontSearchWindowsUpdate /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /v DriverUpdateWizardWuSearchEnabled /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Device Metadata" /v PreventDeviceMetadataFromNetwork /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d "1" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d "0" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "DontSearchWindowsUpdate" /t REG_DWORD /d "1" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "DriverUpdateWizardWuSearchEnabled" /t REG_DWORD /d "0" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d "1" /f >nul
)

REM Add Windows Update Toggler
copy /b /y "%~dp0hotfixes\WindowsUpdate\Toggle_WindowsUpdate.cmd" "%~dp0mount\Windows" >nul
copy /b /y "%~dp0hotfixes\WindowsUpdate\Toggle Windows Update.lnk" "%~dp0mount\ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools" >nul


REM Disable P2P Windows Update
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "99" /f >nul

REM Disable User Account Control
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 0 /f >nul

REM Disable MSHTA and WebView
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Hta" /v "DisableHTMLApplication" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "WebView" /t REG_DWORD /d 0 /f >nul

REM Disable Windows Defender, MRT, SmartScreen
Reg add "HKLM\TK_DEFAULT\SOFTWARE\Microsoft\Windows Security Health\State" /v "AccountProtection_MicrosoftAccount_Disconnected" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows Security Health\State" /v "AccountProtection_MicrosoftAccount_Disconnected" /t REG_DWORD /d "0" /f >nul

if "%DisableDefender%"=="0" goto skipDisableDefender
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Defender Security Center\Notifications" /v "DisableEnhancedNotifications" /t REG_DWORD /d "1" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d "1" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtectionSource" /t REG_DWORD /d "2" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Defender\Signature Updates" /v "FirstAuGracePeriod" /t REG_DWORD /d "0" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Defender\UX Configuration" /v "DisablePrivacyMode" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUAU" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MRT" /v "DontReportInfectionInformation" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray" /v "HideSystray" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender" /v "PUAProtection" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender" /v "RandomizeScheduleTaskTimes" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions" /v "DisableAutoExclusions" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v "MpEnablePus" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine" /v "LocalSettingOverridePurgeItemsAfterDelay" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine" /v "PurgeItemsAfterDelay" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScriptScanning" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Remediation" /v "Scan_ScheduleDay" /t REG_DWORD /d "8" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Remediation" /v "Scan_ScheduleTime" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "AdditionalActionTimeOut" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "CriticalFailureTimeOut" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableGenericRePorts" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "NonCriticalTimeOut" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "AvgCPULoadFactor" /t REG_DWORD /d "10" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "DisableArchiveScanning" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "DisableCatchupFullScan" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "DisableCatchupQuickScan" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "DisableRemovableDriveScanning" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "DisableRestorePoint" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "DisableScanningMappedNetworkDrivesForFullScan" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "DisableScanningNetworkFiles" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "PurgeItemsAfterDelay" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "ScanOnlyIfIdle" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "ScanParameters" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "ScheduleDay" /t REG_DWORD /d 8 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v "ScheduleTime" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "DisableUpdateOnStartupWithoutEngine" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ForceUpdateFromMU" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ScheduleDay" /t REG_DWORD /d 8 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ScheduleTime" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "SignatureUpdateCatchupInterval" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\EventLog\System\Microsoft-Antimalware-ShieldProvider" /v "Start" /t REG_DWORD /d "4" /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\EventLog\System\WinDefend" /v "Start" /t REG_DWORD /d "4" /f >nul

set "DisableServices=%DisableServices%,MsSecFlt,Sense,WdBoot,WdFilter,WdNisDrv,WdNisSvc,WinDefend"
set RemoveTasks=%RemoveTasks%,"Windows Defender\Windows Defender Cache Maintenance","Windows Defender\Windows Defender Cleanup","Windows Defender\Windows Defender Scheduled Scan","Windows Defender\Windows Defender Verification"
set DisableTrackers=%DisableTrackers%,"DefenderApiLogger","DefenderAuditLogger"
:skipDisableDefender

REM MAPS/SpyNet will be always disabled for privacy
if not "%DisableDefender%"=="0" set DisableSpyNet=1
if "%DisableSpyNet%"=="0" goto skipDisableSpyNet
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "LocalSettingOverrideSpynetReporting" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpyNetReporting" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpyNetReportingLocation" /t REG_MULTI_SZ /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d "2" /f >nul
:skipDisableSpyNet

REM Remove Security Health system tray Icon
Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v SecurityHealth /f >nul 2>&1

REM SmartScreen will be always disabled
Reg add "HKLM\TK_DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "PreventOverride" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_DEFAULT\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "PreventOverride" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Security Health\State" /v "AppAndBrowser_StoreAppsSmartScreenOff" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f >nul
Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\PhishingFilter" /v "EnabledV9" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\PhishingFilter" /v "PreventOverride" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter" /v "EnabledV9" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter" /v "PreventOverride" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v "ConfigureAppInstallControlEnabled" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v "ConfigureAppInstallControl" /t REG_SZ /d "Anywhere" /f >nul


REM Enable My Computer Icon on desktop
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul

REM Disable text autocorrection 
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableSpellchecking" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableAutocorrection" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableDoubleTapSpace" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnablePredictionSpaceInsertion" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableTextPrediction" /t REG_DWORD /d 0 /f >nul

REM Disable Special Keys Combination
reg add "HKLM\TK_NTUSER\Control Panel\Accessibility\HighContrast" /v "Flags" /t REG_SZ /d "122" /f >nul
reg add "HKLM\TK_NTUSER\Control Panel\Accessibility\MouseKeys" /v "Flags" /t REG_SZ /d "58" /f >nul
reg add "HKLM\TK_NTUSER\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f >nul
reg add "HKLM\TK_NTUSER\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "58" /f >nul
reg add "HKLM\TK_NTUSER\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul

REM Media Player Tweaks
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "AcceptedPrivacyStatement" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "UpgradeCheckFrequency" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "MediaLibraryCreateNewDatabase" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "MetadataRetrieval" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "SilentAcquisition" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "UsageTracking" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "DisableMRUMusic" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "DisableMRUPictures" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "DisableMRUVideo" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "DisableMRUPlaylists" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "FirstRun" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "LaunchIndex" /t REG_DWORD /d 1 /f >nul


REM Internet Explorer Settings
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "about:blank" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "Search Page" /t REG_SZ /d "https://www.google.com/" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "SmoothScroll" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "WarnOnClose" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "OpenAllHomePages" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "Groups" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "NewTabPageShow" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "PopupsUseNewWindow" /t REG_DWORD /d 0 /f >nul

reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "Use FormSuggest" /t REG_SZ /d "no" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "FormSuggest Passwords" /t REG_SZ /d "no" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "FormSuggest PW Ask" /t REG_SZ /d "no" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\DomainSuggestion" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\IntelliForms" /v "AskUser" /t REG_DWORD /d 0 /f >nul

reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\New Windows" /v "PlaySound" /t REG_DWORD /d 0 /f >nul
 
REM Disable AutoSuggest in Explorer address bar
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "AutoSuggest " /t REG_SZ /d "no" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "Append Completion" /t REG_SZ /d "no" /f >nul


reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Main" /v "DisableFirstRunCustomize" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Main" /v "DisableIEAppNotificationPolicy" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Recovery" /v "AutoRecover" /t REG_DWORD /d 2 /f >nul

reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "about:blank" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "Search Page" /t REG_SZ /d "https://www.google.com/" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "Default_Page_URL" /t REG_SZ /d "about:blank" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "Default_Search_URL" /t REG_SZ /d "https://www.google.com/" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "EnableAutoUpgrade" /t REG_DWORD /d 0 /f >nul


reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Suggested Sites" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer" /v "AllowServicePoweredQSA" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Geolocation" /v "PolicyDisableGeolocation" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Feeds" /v "DisableFeedPane" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Feeds" /v "BackgroundSyncStatus" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Feed Discovery" /v "Enabled" /t REG_DWORD /d 0 /f >nul

reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main\WindowsSearch" /v "EnabledScopes" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "AutoSuggest" /t REG_SZ /d "no" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\VersionManager" /v "DownloadVersionList" /t REG_DWORD /d 0 /f >nul

 
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "HideZoneInfoOnProperties" /t REG_DWORD /d 1 /f >nul

REM Replace Bing with Google
reg delete "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0633EE93-D776-472f-A0FF-E1416B8B2E3A}" /f >nul 2>&1

reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "DefaultScope" /t REG_SZ /d "{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "DownloadUpdates" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "Version" /t REG_DWORD /d 4 /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "ShowSearchSuggestionsInAddressGlobal" /t REG_DWORD /d 0 /f >nul

reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "DisplayName" /t REG_SZ /d "Google" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "URL" /t REG_SZ /d "https://www.google.com/search?q={searchTerms}" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "ShowSearchSuggestions" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "SuggestionsURL_JSON" /t REG_SZ /d "https://suggestqueries.google.com/complete/search?output=firefox&client=firefox&qu={searchTerms}" /f >nul
reg delete "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "FaviconURL" /f >nul 2>&1

reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Restrictions" /v "NoHelpItemSendFeedback" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Restrictions" /v "NoHelpItemNetscapeHelp" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Restrictions" /v "NoHelpItemTipOfTheDay" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Restrictions" /v "NoHelpItemTutorial" /t REG_DWORD /d 1 /f >nul

REM Windows Media Player Privacy
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" /v "DisableAutoUpdate" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" /v "PreventLibrarySharing" /t REG_DWORD /d 1 /f >nul


REM Disable Metered Connections
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" /v "3G" /t REG_DWORD /d 1 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" /v "4G" /t REG_DWORD /d 1 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" /v "Default" /t REG_DWORD /d 1 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" /v "Ethernet" /t REG_DWORD /d 1 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" /v "WiFi" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WwanSvc\NetCost" /v "Cost3G" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WwanSvc\NetCost" /v "Cost4G" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Wireless\NetCost" /v "Cost" /t REG_DWORD /d 1 /f >nul
set "DisableServices=%DisableServices%,DusmSvc"


REM Disable IPv6 Internet Connection Sharing and disable outdated transitional protocols
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\TCPIP6\Parameters" /v "EnableICSIPv6" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\TCPIP6\Parameters" /v "DisabledComponents" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\TCPIP\v6Transition" /v "6to4_State" /t REG_SZ /d "Disabled" /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\TCPIP\v6Transition" /v "ISATAP_State" /t REG_SZ /d "Disabled" /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\TCPIP\v6Transition" /v "Teredo_State" /t REG_SZ /d "Disabled" /f >nul
set "DisableServices=%DisableServices%,iphlpsvc"

REM Disable Autoshare Disks over LAN network for security
reg add "HKLM\TK_SYSTEM\ControlSet001\Services\lanmanserver\parameters" /v AutoShareWks /t REG_DWORD /d 0 /f >nul

REM Disable IPv4 Autoconfig
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\Tcpip\Parameters" /v "IPAutoconfigurationEnabled" /t REG_DWORD /d "0" /f >nul

REM Disable IP source routing for security
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\Tcpip\Parameters" /v "DisableIPSourceRouting" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\Tcpip6\Parameters" /v "DisableIPSourceRouting" /t REG_DWORD /d "2" /f >nul

REM Disable Internet Connection Sharing
reg add "HKLM\TK_SOFTWARE\Microsoft\WcmSvc\Tethering" /v "RemoteStartupDisabled" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Network Connections" /v "NC_ShowSharedAccessUI" /t REG_DWORD /d "0" /f >nul
set "DisableServices=%DisableServices%,SharedAccess,icssvc"

REM Disable Remote Assistance
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fAllowToGetHelp" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fAllowUnsolicited" /t REG_DWORD /d "0" /f >nul
set RemoveTasks=%RemoveTasks%,"RemoteAssistance\RemoteAssistanceTask"

REM Disable Windows Connect Now
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars" /v "EnableRegistrars" /t REG_DWORD /d "0" /f >nul
set "DisableServices=%DisableServices%,wcncsvc"

REM Disable Hotspot Authentication
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\HotspotAuthentication" /v "Enabled" /t REG_DWORD /d "0" /f >nul

REM Disable LLTD protocol
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\LLTD" /v "EnableLLTDIO" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\LLTD" /v "EnableRspndr" /t REG_DWORD /d "0" /f >nul
set "DisableServices=%DisableServices%,lltdsvc"

REM Disable obsolete LLNR protocol
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d 0 /f >nul

REM Disable obsolete NetBIOS name resolution
reg add "HKLM\TK_SYSTEM\ControlSet001\services\Dnscache\Parameters" /v "EnableNetbios" /t REG_DWORD /d "0" /f >nul

REM Disable Distributed Component Object Model
reg add "HKLM\TK_SOFTWARE\Microsoft\Ole" /v "EnableDCOM" /t REG_SZ /d "N" /f >nul

REM Disable Peer-to-peer networking services
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Peernet" /v "Disabled" /t REG_DWORD /d "1" /f >nul
set "DisableServices=%DisableServices%,PNRPsvc,PNRPAutoReg,p2pimsvc,p2psvc"

REM Disable Mobile Device Manamagment Enrollment
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM" /v "DisableRegistration" /t REG_DWORD /d "1" /f >nul
set RemoveTasks=%RemoveTasks%,"BitLocker\BitLocker MDM policy Refresh","EnterpriseMgmt\MDMMaintenenceTask","ExploitGuard\ExploitGuard MDM policy Refresh"

REM Disable Meltdown and Spectre fixes for speed
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul

REM Disable AutoPlay for other drives than CD/DVD - for security
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HonorAutoRunSetting" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HonorAutoRunSetting" /t REG_DWORD /d 1 /f >nul
if "%DisableCDAutoPlay%"=="0" (
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d 223 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d 223 /f >nul
)
if not "%DisableCDAutoPlay%"=="0" (
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d 255 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d 255 /f >nul
)


REM Set default NTP time server
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /ve /t REG_SZ /d "0" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /v "0" /t REG_SZ /d "%NTPserver%" /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time" /v "Start" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\Parameters" /v "NtpServer" /t REG_SZ /d "%NTPserver%,0x9" /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\Parameters" /v "Type" /t REG_SZ /d "NTP" /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\TimeProviders\NtpClient" /v "Enabled" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\TimeProviders\NtpClient" /v "SpecialPollInterval" /t REG_DWORD /d 86400 /f >nul
reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\TimeProviders\NtpClient" /v "SpecialPollTimeRemaining" /f >nul 2>&1

REM Disable Time Sync NTP server
reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\W32time\TimeProviders\NtpServer" /v "Enabled" /t REG_DWORD /d "0" /f >nul

REM Disable Time Sync entirely
if not "%DisableTimeSync%"=="0" (
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\W32time\TimeProviders\NtpClient" /v "Enabled" /t REG_DWORD /d "0" /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\Parameters" /v "Type " /t REG_SZ /d "NoSync" /f >nul
 set "DisableServices=%DisableServices%,W32Time"
 set RemoveTasks=%RemoveTasks%,"Time Synchronization\ForceSynchronizeTime","Time Synchronization\SynchronizeTime","Time Zone\SynchronizeTimeZone"
)


REM Remove WSearch service entirely
if not "%DisableSearchService%"=="0" (
 reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\WSearch" /f >nul 2>&1
 reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\WSearchIdxPi" /f >nul 2>&1
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\InfoBarsDisabled" /v "ServerMSSNotInstalled" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_SearchFiles" /t REG_DWORD /d 0 /f >nul
 set "DisableServices=%DisableServices%,CDPSvc,CDPUserSvc,NcbService"
 set DisableSearchIndexing=1
)

REM Prevent WSearch service from indexing files in the background.
if not "%DisableSearchIndexing%"=="0" (
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "PreventIndexingLowDiskSpaceMB" /t REG_DWORD /d 0x7fffffff /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "PreventIndexOnBattery" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "PreventIndexingEmailAttachments" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "PreventIndexingOfflineFiles" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "PreventIndexingOutlook" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "PreventIndexingPublicFolders" /t REG_DWORD /d 1 /f >nul
)


REM Disable F1 to get help
if "%ImageArchitecture%"=="x86" reg add "HKLM\TK_NTUSER\SOFTWARE\Classes\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f >nul
if "%ImageArchitecture%"=="x64" reg add "HKLM\TK_NTUSER\SOFTWARE\Classes\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f >nul

REM Disable Animations
reg add "HKLM\TK_DEFAULT\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012078010000000 /f >nul
reg add "HKLM\TK_DEFAULT\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul
reg add "HKLM\TK_NTUSER\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012078010000000 /f >nul
reg add "HKLM\TK_NTUSER\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul


REM Disable legacy PC speaker sound service which is as old as 1980 era
set "DisableServices=%DisableServices%,Beep"

REM Disable Sounds and Beeps
reg add "HKLM\TK_NTUSER\Control Panel\Sound" /v "Beep" /t REG_SZ /d "no" /f >nul
reg add "HKLM\TK_NTUSER\Control Panel\Sound" /v "ExtendedSounds" /t REG_SZ /d "no" /f >nul
reg add "HKLM\TK_NTUSER\AppEvents\Schemes" /ve /t REG_SZ /d ".None" /f >nul
for /f "tokens=1 delims=" %%a in ('reg query "HKLM\TK_NTUSER\AppEvents\Schemes\Apps" 2^>nul ^| find /i "\Schemes\"') do (
 for /f "tokens=1 delims=" %%b in ('reg query "%%a" 2^>nul ^| find /i "%%a\"') do (
  for /f "tokens=1 delims=" %%c in ('reg query "%%b" /e /k /f ".Current" 2^>nul ^| find /i "%%b\.Current"') do (
   reg add "%%c" /ve /t REG_SZ /d "" /f >nul
  )
 ) 
)


REM Disable prefetcher
if not "%DisablePrefetcher%"=="0" (
 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /f /v EnableSuperfetch /t REG_DWORD /d 0 >nul
 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /f /v EnablePrefetcher /t REG_DWORD /d 0 >nul
 set "DisableServices=%DisableServices%,SysMain"
 set RemoveTasks=%RemoveTasks%,"Sysmain\HybridDriveCachePrepopulate","Sysmain\HybridDriveCacheRebalance","Sysmain\ResPriStaticDbSync","Sysmain\WsSwapAssessmentTask"
)

REM Various system tweaks
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\CrashControl" /v CrashDumpEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\CrashControl" /v LogEvent /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\CrashControl" /v EnableLogFile /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager" /v AutoChkTimeOut /t REG_DWORD /d 1 /f >nul

REM Disable fast startup for better reliability
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul

REM Disable hibernation
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power" /v HibernateEnabledDefault /t REG_DWORD /d 0 /f >nul

REM Disable USB AutoSuspend for Balanced and High Performance power schemes
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\381b4222-f694-41f0-9685-ff5bb260df2e\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226" /v ACSettingIndex /t REG_DWORD /d 0 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\381b4222-f694-41f0-9685-ff5bb260df2e\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226" /v DCSettingIndex /t REG_DWORD /d 0 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226" /v ACSettingIndex /t REG_DWORD /d 0 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226" /v DCSettingIndex /t REG_DWORD /d 0 /f >nul

REM Disable idle Hard Disk auto power off for Balanced and High Performance power schemes
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\381b4222-f694-41f0-9685-ff5bb260df2e\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e" /v ACSettingIndex /t REG_DWORD /d 0 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\381b4222-f694-41f0-9685-ff5bb260df2e\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e" /v DCSettingIndex /t REG_DWORD /d 0 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e" /v ACSettingIndex /t REG_DWORD /d 0 /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e" /v DCSettingIndex /t REG_DWORD /d 0 /f >nul


REM Disable loggers
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Diagnostics\Performance" /v "DisableDiagnosticTracing" /t REG_DWORD /d "1" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Diagnostics\Performance\BootCKCLSettings" /v "Start" /t REG_DWORD /d "0" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Diagnostics\Performance\SecondaryLogonCKCLSettings" /v "Start" /t REG_DWORD /d "0" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Diagnostics\Performance\ShutdownCKCLSettings" /v "Start" /t REG_DWORD /d "0" /f >nul

reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f >nul

REM Disable WBEM logs
reg add "HKLM\TK_SOFTWARE\Microsoft\WBEM\CIMOM" /v "Logging" /t REG_DWORD /d 0 /f >nul

REM Disable CBS logging
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing" /v "EnableLog" /t REG_DWORD /d "0" /f >nul

REM Disable Reserved Storage
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v "ShippedWithReserves" /t REG_DWORD /d "0" /f >nul

REM Set Software Protection Platform service to manual, disable logging and remove tasks
reg add "HKLM\TK_SYSTEM\ControlSet001\Services\sppsvc" /v "Start" /t REG_DWORD /d "3" /f >nul
reg add "HKLM\TK_SYSTEM\ControlSet001\Services\EventLog\Application\Software Protection Platform Service" /v "Start" /t REG_DWORD /d "4" /f >nul
reg add "HKLM\TK_SYSTEM\ControlSet001\Services\EventLog\Application\Microsoft-Windows-Security-SPP" /v "Start" /t REG_DWORD /d "4" /f >nul
reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\Autologger\EventLog-Application\{e23b33b0-c8c9-472c-a5f9-f2bdfea0f156}" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Security-SPP-UX-GenuineCenter-Logging/Operational" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Security-SPP-UX-Notifications/ActionCenter" /v "Enabled" /t REG_DWORD /d 0 /f >nul
set RemoveTasks=%RemoveTasks%,"SoftwareProtectionPlatform\SvcRestartTask","SoftwareProtectionPlatform\SvcRestartTaskLogon","SoftwareProtectionPlatform\SvcRestartTaskNetwork"


ECHO.
ECHO.
ECHO ========================================
echo Disabling trackers/loggers...
ECHO ========================================
ECHO.

for %%t in (%DisableTrackers%) do (
 for /f "tokens=1 delims=" %%a in ('reg query "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\Autologger" /e /k /f "%%~t" 2^>nul ^| find /i "%%~t"') do (
    ECHO Disabling tracker %%~t
    "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\Autologger\%%~t" /v "Start" /t REG_DWORD /d "0" /f >nul
  )
)


ECHO.
ECHO.
ECHO ========================================
echo Disabling services...
ECHO ========================================
ECHO.

REM Disable Services loop
for %%s in (%DisableServices%) do (
 for /f "tokens=1 delims=" %%a in ('reg query "HKLM\TK_SYSTEM\ControlSet001\Services" /e /k /f "%%s" 2^>nul ^| find /i "%%s"') do (
    ECHO Disabling service %%s
    "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SYSTEM\ControlSet001\Services\%%s" /v "Start" /t REG_DWORD /d "4" /f >nul
  )
)

ECHO.
ECHO.
ECHO ========================================
echo Removing tasks from task scheduler...
ECHO ========================================
ECHO.


for %%t in (%RemoveTasks%) do (
 for /f "tokens=3 delims= " %%a in ('reg query "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\%%~t" /v "Id" 2^>nul ^| find /i "Id" ^| find /i "REG_SZ"') do (
  ECHO Removing task %%~t
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\%%~t" /f >nul 2>&1
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Maintenance\%%a" /f >nul 2>&1
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\%%a" /f >nul 2>&1
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\%%a" /f >nul 2>&1
 )
)


ECHO.
ECHO.
ECHO ==============================================
echo Removing permissions for system UWP apps...
ECHO ==============================================
ECHO.


for %%p in (%DisableSysUWPpermissions%) do (
 for /f "tokens=1 delims=" %%a in ('reg query "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\Capabilities" /e /k /f "%%p" 2^>nul ^| find /i "%%p"') do (
    for /f "tokens=1 delims=" %%b in ('reg query "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\Capabilities\%%p\Apps" 2^>nul ^| find "\Apps\"') do (
      echo.
      echo Removing registry key
      echo %%b
     "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait Reg delete "%%b" /f >nul 2>&1
    )
  )
)


ECHO.
ECHO.
ECHO ==========================================================
echo Set default permissions for apps to disabled state...
ECHO ==========================================================
ECHO.

REM By default disable most permisions for UWP apps
for %%p in (%DisableUWPpermissions%) do (
 for /f "tokens=1 delims=" %%a in ('reg query "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore" /e /k /f "%%p" 2^>nul ^| find /i "%%p"') do (
    ECHO Disabling UWP permission %%p for local machine
    reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\%%p" /v "Value" /t REG_SZ /d "Deny" /f >nul
  )

 for /f "tokens=1 delims=" %%a in ('reg query "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore" /e /k /f "%%p" 2^>nul ^| find /i "%%p"') do (
    ECHO Disabling UWP permission %%p for current user
    reg add "HKLM\TK_NTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\%%p" /v "Value" /t REG_SZ /d "Deny" /f >nul
  )
)


ECHO.
ECHO ==============================================
echo Removing system UWP apps...
ECHO ==============================================
ECHO.

REM Remove unnecessary System UWP apps from the Registry
for %%u in (%RemoveSystemUWPapps%) do (
 ECHO Removing %%u from the Registry
 for /f "tokens=1 delims=" %%a in ('reg query "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore" /s /f "%%u" /k 2^>nul ^| find /i "HKEY_LOCAL_MACHINE\TK_SOFTWARE\"') do (
    reg delete "%%a" /f >nul 2>&1
  )
)

REM Remove unnecessary System UWP apps from Disk
if "%RemoveSystemUWPappsAlsoFromDisk%"=="0" goto skipRemoveSysUWPFromDisk
for %%u in (%RemoveSystemUWPapps%) do (
 for /f "tokens=1 delims=" %%a in ('dir /b /ad "%~dp0mount\Windows\SystemApps" 2^>nul ^| find /i "%%u"') do (
    ECHO Removing %%a from Disk
    "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait cmd /c "rd /s /q "%~dp0mount\Windows\SystemApps\%%a""
  )
)
:skipRemoveSysUWPFromDisk

ECHO.
ECHO ==============================================
echo Applying remaining settings...
ECHO ==============================================
ECHO.


REM Disable Automatic Update of root certificates
if "%DisableRootCertUpdate%"=="1" (
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\SystemCertificates\AuthRoot" /v "DisableRootAutoUpdate" /t REG_DWORD /d 1 /f >nul
)


REM Disable Internet Connection Checking
if not "%DisableInternetConnectionChecking%"=="0" (
 reg add "HKLM\TK_SYSTEM\ControlSet001\Services\NlaSvc\Parameters\Internet" /v "EnableActiveProbing" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" /v "NoActiveProbe" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Network Connections" /v "NC_DoNotShowLocalOnlyIcon" /t REG_DWORD /d 1 /f >nul
)

REM Disable "Shortcut" word when creating shortcuts
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "Link" /t REG_BINARY /d 00000000 /f >nul

REM Enable Fraunhofer IIS MP3 Professional Codec
if "%ImageArchitecture%"=="x64" (
 reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\drivers.desc" /v "X:\Windows\SysWOW64\l3codeca.acm" /f >nul 2>&1
 reg add "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\drivers.desc" /v "X:\Windows\SysWOW64\l3codecp.acm" /t REG_SZ /d "Fraunhofer IIS MPEG Audio Layer-3 Codec (professional)" /f >nul
 reg add "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Drivers32" /v "msacm.l3acm" /t REG_SZ /d "X:\Windows\SysWOW64\l3codecp.acm" /f >nul
)

reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\drivers.desc" /v "X:\Windows\System32\l3codeca.acm" /f >nul 2>&1
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\drivers.desc" /v "X:\Windows\System32\l3codecp.acm" /t REG_SZ /d "Fraunhofer IIS MPEG Audio Layer-3 Codec (professional)" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Drivers32" /v "msacm.l3acm" /t REG_SZ /d "X:\Windows\System32\l3codecp.acm" /f >nul


REM Enable WMP11 WebMedia support
reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\system32\unregmp2.exe,-9905" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\system32\wmploc.dll,-731" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM\shell" /ve /t REG_SZ /d "Play" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM\shell\play" /ve /t REG_SZ /d "&Play" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM\shell\play" /v MUIVerb /t REG_EXPAND_SZ /d "@%%SystemRoot%%\system32\unregmp2.exe,-9991" /f >nul
if "%ImageArchitecture%"=="x86" (
 reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM\shell\play\command" /ve /t REG_EXPAND_SZ /d "\"%%ProgramFiles%%\Windows Media Player\wmplayer.exe\" /prefetch:6 /Play \"%%L\"" /f >nul
 reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM\shell\open\command" /ve /t REG_EXPAND_SZ /d "\"%%ProgramFiles%%\Windows Media Player\wmplayer.exe\" /prefetch:6 /Open \"%%L\"" /f >nul
)
if not "%ImageArchitecture%"=="x64" goto skipWebMx64
 reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM\shell\play\command" /ve /t REG_EXPAND_SZ /d "\"%%ProgramFiles(x86)%%\Windows Media Player\wmplayer.exe\" /prefetch:6 /Play \"%%L\"" /f >nul
 reg add "HKLM\TK_SOFTWARE\Classes\WMP11.AssocFile.WebM\shell\open\command" /ve /t REG_EXPAND_SZ /d "\"%%ProgramFiles(x86)%%\Windows Media Player\wmplayer.exe\" /prefetch:6 /Open \"%%L\"" /f >nul
:skipWebMx64
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".webm" /t REG_SZ /d "WMP11.AssocFile.WebM" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Player\Extensions\.webm" /v "Runtime" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Player\Extensions\.webm" /v "Permissions" /t REG_DWORD /d "1" /f >nul


REM Enable classic Win32 Photo Viewer
reg add "HKLM\TK_SOFTWARE\Classes\Applications\photoviewer.dll\shell\open" /v "MuiVerb" /t REG_SZ /d "@photoviewer.dll,-3043" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\DropTarget" /v "Clsid" /t REG_SZ /d "{60fd46de-f830-4894-a628-6fa81bc0190d}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Bitmap" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll,-3056" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Bitmap" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Bitmap\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-70" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Bitmap\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Bitmap\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Gif" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll,-3057" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Gif" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Gif\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-83" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Gif\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Gif\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.JFIF" /v "EditFlags" /t REG_DWORD /d "65536" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.JFIF" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll,-3055" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.JFIF" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.JFIF\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-72" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.JFIF\shell\open" /v "MuiVerb" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\photoviewer.dll,-3043" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.JFIF\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.JFIF\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Jpeg" /v "EditFlags" /t REG_DWORD /d "65536" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Jpeg" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll,-3055" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Jpeg" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Jpeg\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-72" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Jpeg\shell\open" /v "MuiVerb" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\photoviewer.dll,-3043" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Jpeg\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Jpeg\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Png" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll,-3057" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Png" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Png\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-71" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Png\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Png\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.HEIF" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll,-3057" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.HEIF" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.HEIF\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-71" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.HEIF\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.HEIF\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.WebP" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll,-3057" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.WebP" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.WebP\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-71" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.WebP\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.WebP\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll,-3058" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\imageres.dll,-122" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff\shell\open" /v "MuiVerb" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\photoviewer.dll,-3043" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Wdp" /v "EditFlags" /t REG_DWORD /d "65536" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Wdp" /v "ImageOptionFlags" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Wdp\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\wmphoto.dll,-400" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Wdp\shell\open" /v "MuiVerb" /t REG_EXPAND_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\photoviewer.dll,-3043" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Wdp\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\PhotoViewer.FileAssoc.Wdp\shell\open\DropTarget" /v "Clsid" /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities" /v "ApplicationDescription" /t REG_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\photoviewer.dll,-3069" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities" /v "ApplicationName" /t REG_SZ /d "@%%ProgramFiles%%\Windows Photo Viewer\photoviewer.dll,-3009" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".bmp" /t REG_SZ /d "PhotoViewer.FileAssoc.Bitmap" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".dib" /t REG_SZ /d "PhotoViewer.FileAssoc.Bitmap" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".gif" /t REG_SZ /d "PhotoViewer.FileAssoc.Gif" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jfif" /t REG_SZ /d "PhotoViewer.FileAssoc.JFIF" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpe" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpeg" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpg" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jxr" /t REG_SZ /d "PhotoViewer.FileAssoc.Wdp" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".png" /t REG_SZ /d "PhotoViewer.FileAssoc.Png" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".tif" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".tiff" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".wdp" /t REG_SZ /d "PhotoViewer.FileAssoc.Wdp" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".heif" /t REG_SZ /d "PhotoViewer.FileAssoc.HEIF" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".webp" /t REG_SZ /d "PhotoViewer.FileAssoc.WebP" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "emffile_.emf" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "rlefile_.rle" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "wmffile_.wmf" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "GlobalAssocChangedCounter" /t REG_DWORD /d "13" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.bmp\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.bmp\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.bmp\UserChoice" /v "Hash" /t REG_SZ /d "TDU75KWAGi4=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.bmp\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Bitmap" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.dib\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.dib\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.dib\UserChoice" /v "Hash" /t REG_SZ /d "hAQpLYJfRYE=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.dib\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Bitmap" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.gif\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.gif\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.gif\UserChoice" /v "Hash" /t REG_SZ /d "1in4hcmDrB4=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.gif\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Gif" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jfif\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jfif\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jfif\UserChoice" /v "Hash" /t REG_SZ /d "Y5upkzp3g5E=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jfif\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.JFIF" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpe\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpe\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpe\UserChoice" /v "Hash" /t REG_SZ /d "ZIeqfdrNtFk=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpe\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpeg\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpeg\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpeg\UserChoice" /v "Hash" /t REG_SZ /d "iVWM3EAePKw=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpeg\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpg\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpg\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpg\UserChoice" /v "Hash" /t REG_SZ /d "Xq9gH4jXoFM=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpg\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jxr\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jxr\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jxr\UserChoice" /v "Hash" /t REG_SZ /d "ahz7f/Yl09M=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jxr\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Wdp" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.png\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.png\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.png\UserChoice" /v "Hash" /t REG_SZ /d "Evm7jp++AWA=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.png\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Png" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tif\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tif\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tif\UserChoice" /v "Hash" /t REG_SZ /d "wEj9gLqtYH4=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tif\UserChoice" /v "ProgId" /t REG_SZ /d "TIFImage.Document" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tiff\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tiff\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tiff\UserChoice" /v "Hash" /t REG_SZ /d "/r2V12Yryig=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.tiff\UserChoice" /v "ProgId" /t REG_SZ /d "TIFImage.Document" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.wdp\OpenWithList" /v "a" /t REG_SZ /d "PhotoViewer.dll" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.wdp\OpenWithList" /v "MRUList" /t REG_SZ /d "a" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.wdp\UserChoice" /v "Hash" /t REG_SZ /d "/qcrPB0bhuI=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.wdp\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Wdp" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.bmp\UserChoice" /v "Hash" /t REG_SZ /d "rEigxhAPyos=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.bmp\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Bitmap" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.dib\UserChoice" /v "Hash" /t REG_SZ /d "R60f5QZs3Hg=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.dib\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Bitmap" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.gif\UserChoice" /v "Hash" /t REG_SZ /d "YcQO9pssSPU=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.gif\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Gif" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jfif\UserChoice" /v "Hash" /t REG_SZ /d "5yjvWKb+Jns=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jfif\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.JFIF" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jpe\UserChoice" /v "Hash" /t REG_SZ /d "TujD2rCi+po=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jpe\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jpeg\UserChoice" /v "Hash" /t REG_SZ /d "wdZ9wQI4vW8=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jpeg\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jpg\UserChoice" /v "Hash" /t REG_SZ /d "3xY0V0JOiFc=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jpg\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jxr\UserChoice" /v "Hash" /t REG_SZ /d "ENXEd5Uzg84=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.jxr\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Wdp" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.png\UserChoice" /v "Hash" /t REG_SZ /d "SPesrUKrIFE=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.png\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Png" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.tif\UserChoice" /v "Hash" /t REG_SZ /d "bCXQRSAHD/I=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.tif\UserChoice" /v "ProgId" /t REG_SZ /d "TIFImage.Document" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.tiff\UserChoice" /v "Hash" /t REG_SZ /d "7F/LfjhVnes=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.tiff\UserChoice" /v "ProgId" /t REG_SZ /d "TIFImage.Document" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.wdp\UserChoice" /v "Hash" /t REG_SZ /d "tu0JqOen+Es=" /f >nul
reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\Roaming\OpenWith\FileExts\.wdp\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Wdp" /f >nul

REM Enable classic Win32 Calculator
reg add "HKLM\TK_SOFTWARE\RegisteredApplications" /v "Windows Calculator" /t REG_SZ /d "SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Calculator\Capabilities" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Calculator\Capabilities" /v "ApplicationName" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\system32\win32calc.exe" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Calculator\Capabilities" /v "ApplicationDescription" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\system32\win32calc.exe,-217" /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Calculator\Capabilities\URLAssociations" /v "calculator" /t REG_SZ /d "calculator" /f >nul

if exist "%~dp0mount\Windows\SysWOW64" (
 reg add "HKLM\TK_SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Applets\Calculator\Capabilities" /v "ApplicationName" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\system32\win32calc.exe" /f >nul
 reg add "HKLM\TK_SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Applets\Calculator\Capabilities" /v "ApplicationDescription" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\system32\win32calc.exe,-217" /f >nul
 reg add "HKLM\TK_SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Applets\Calculator\Capabilities\URLAssociations" /v "calculator" /t REG_SZ /d "calculator" /f >nul
 
 copy /b /y "%~dp0hotfixes\win32calc\x64\win32calc.exe" "%~dp0mount\Windows\System32" >nul
 copy /b /y "%~dp0hotfixes\win32calc\x86\win32calc.exe" "%~dp0mount\Windows\SysWOW64" >nul
 for %%l in (ar-SA,bg-BG,cs-CZ,da-DK,de-DE,el-GR,en-GB,en-US,es-ES,es-MX,et-EE,fi-FI,fr-CA,fr-FR,he-IL,hr-HR,hu-HU,it-IT,ja-JP,ko-KR,lt-LT,lv-LV,nb-NO,nl-NL,pl-PL,pt-BR,pt-PT,ro-RO,ru-RU,sk-SK,sl-SI,sr-Latn-RS,sv-SE,th-TH,tr-TR,uk-UA,zh-CN,zh-TW) do (
  if exist "%~dp0mount\Windows\System32\%%l\winver.exe.mui" copy /b /y "%~dp0hotfixes\win32calc\MUI\%%l\x64\win32calc.exe.mui" "%~dp0mount\Windows\System32\%%l" >nul
  if exist "%~dp0mount\Windows\SysWOW64\%%l\winver.exe.mui" copy /b /y "%~dp0hotfixes\win32calc\MUI\%%l\x86\win32calc.exe.mui" "%~dp0mount\Windows\SysWOW64\%%l" >nul
 )
)

if not exist "%~dp0mount\Windows\SysWOW64" (
 copy /b /y "%~dp0hotfixes\win32calc\x86\win32calc.exe" "%~dp0mount\Windows\System32" >nul
 for %%l in (ar-SA,bg-BG,cs-CZ,da-DK,de-DE,el-GR,en-GB,en-US,es-ES,es-MX,et-EE,fi-FI,fr-CA,fr-FR,he-IL,hr-HR,hu-HU,it-IT,ja-JP,ko-KR,lt-LT,lv-LV,nb-NO,nl-NL,pl-PL,pt-BR,pt-PT,ro-RO,ru-RU,sk-SK,sl-SI,sr-Latn-RS,sv-SE,th-TH,tr-TR,uk-UA,zh-CN,zh-TW) do (
  if exist "%~dp0mount\Windows\System32\%%l\winver.exe.mui" copy /b /y "%~dp0hotfixes\win32calc\MUI\%%l\x86\win32calc.exe.mui" "%~dp0mount\Windows\System32\%%l" >nul
 )
)
copy /b /y "%~dp0hotfixes\win32calc\Calculator.lnk" "%~dp0mount\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories" >nul
attrib -r -s -h "%~dp0mount\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\desktop.ini" >nul
copy /b /y "%~dp0hotfixes\accessories.ini" "%~dp0mount\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\desktop.ini" >nul
attrib +a +s +h "%~dp0mount\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\desktop.ini" >nul

REM Enable support for classic HLP Help files
if "%AddWinHlp%"=="0" goto skipWinHlpSupport

if exist "%~dp0mount\Windows\winhlp32.exe" "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait cmd /c "del /q /f "%~dp0mount\Windows\winhlp32.exe"" >nul 2>&1
copy /b /y "%~dp0hotfixes\WinHlp32\bin\ftlx0411.dll" "%~dp0mount\Windows\System32" >nul
copy /b /y "%~dp0hotfixes\WinHlp32\bin\ftlx041e.dll" "%~dp0mount\Windows\System32" >nul
copy /b /y "%~dp0hotfixes\WinHlp32\bin\ftsrch.dll" "%~dp0mount\Windows\System32" >nul
if exist "%~dp0mount\Windows\SysWOW64" (
 copy /b /y "%~dp0hotfixes\WinHlp32\bin\ftlx0411.dll" "%~dp0mount\Windows\SysWOW64" >nul
 copy /b /y "%~dp0hotfixes\WinHlp32\bin\ftlx041e.dll" "%~dp0mount\Windows\SysWOW64" >nul
 copy /b /y "%~dp0hotfixes\WinHlp32\bin\ftsrch.dll" "%~dp0mount\Windows\SysWOW64" >nul
)
copy /b /y "%~dp0hotfixes\WinHlp32\bin\winhlp32.exe" "%~dp0mount\Windows" >nul
for %%l in (ar-sa,bg-bg,cs-cz,da-dk,de-de,el-gr,en-gb,en-us,es-es,es-mx,et-ee,fi-fi,fr-ca,fr-fr,he-il,hr-hr,hu-hu,it-it,ja-jp,ko-kr,lt-lt,lv-lv,nb-no,nl-nl,pl-pl,pt-br,pt-pt,ro-ro,ru-ru,sk-sk,sl-si,sr-latn-rs,sv-se,th-th,tr-tr,uk-ua,zh-cn,zh-tw) do (
 if exist "%~dp0mount\Windows\%%l\winhlp32.exe.mui" "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E -UseCurrentConsole -Wait cmd /c "del /q /f "%~dp0mount\Windows\%%l\winhlp32.exe.mui"" >nul 2>&1
 if exist "%~dp0mount\Windows\%%l\hh.exe.mui" copy /b /y "%~dp0hotfixes\WinHlp32\MUI\%%l\winhlp32.exe.mui" "%~dp0mount\Windows\%%l" >nul
 if exist "%~dp0mount\Windows\System32\%%l\winver.exe.mui" copy /b /y "%~dp0hotfixes\WinHlp32\MUI\%%l\ftsrch.dll.mui" "%~dp0mount\Windows\System32\%%l" >nul
 if exist "%~dp0mount\Windows\SysWOW64\%%l\winver.exe.mui" copy /b /y "%~dp0hotfixes\WinHlp32\MUI\%%l\ftsrch.dll.mui" "%~dp0mount\Windows\SysWOW64\%%l" >nul
)

reg add "HKLM\TK_SOFTWARE\Classes\.hlp" /ve /t REG_SZ /d "hlpfile" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\hlpfile" /ve /t REG_SZ /d "Help File" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\hlpfile" /v "FriendlyTypeName" /t REG_SZ /d "@shell32.dll,-10145" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\hlpfile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\shell32.dll,23" /f >nul
reg add "HKLM\TK_SOFTWARE\Classes\hlpfile\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\winhlp32.exe %%1" /f >nul

:skipWinHlpSupport

REM Microsoft SysInternals Tools EULA is Accepted by default
reg add "HKLM\TK_NTUSER\Software\Sysinternals\AutoRuns" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\ClockRes" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Coreinfo" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Desktops" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Disk2Vhd" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\DiskExt" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\DiskView" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Du" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\FindLinks" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Handle" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Hex2Dec" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Junction" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\ListDLLs" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Movefile" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\NTFSInfo" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PendMove" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Process Explorer" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Process Monitor" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsExec" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsFile" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsGetSid" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsInfo" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsKill" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsList" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsLoggedon" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsLoglist" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsPasswd" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsPing" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsService" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsShutdown" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsSuspend" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\SDelete" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Share Enum" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\sigcheck" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Streams" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Strings" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Sync" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\TCPView" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\VolumeID" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\TK_NTUSER\Software\Sysinternals\Whois" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul

REM Copy NSudo utility to Program Files
mkdir "%~dp0mount\Program Files\NSudo" >nul 2>&1
copy /b /y "%~dp0tools\%PackagesArchitecture%\NSudo.exe" "%~dp0mount\Program Files\NSudo" >nul
copy /b /y "%~dp0tools\%PackagesArchitecture%\NSudoG.exe" "%~dp0mount\Program Files\NSudo" >nul

REM Create ngen.cmd for compiling .NET Framework
echo @ECHO OFF>"%~dp0mount\Windows\ngen.cmd"
echo TITLE Compiling NET Framework...>>"%~dp0mount\Windows\ngen.cmd"
echo CLS>>"%~dp0mount\Windows\ngen.cmd"
echo if not exist "%%windir%%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto noNET20x86>>"%~dp0mount\Windows\ngen.cmd"
echo ECHO Compiling NET Framework 2.0 (32-bit)>>"%~dp0mount\Windows\ngen.cmd"
echo "%%windir%%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" executeQueuedItems ^>NUL 2^>NUL>>"%~dp0mount\Windows\ngen.cmd"
echo :noNET20x86>>"%~dp0mount\Windows\ngen.cmd"
echo if not exist "%%windir%%\Microsoft.NET\Framework64\v2.0.50727\ngen.exe" goto noNET20x64>>"%~dp0mount\Windows\ngen.cmd"
echo ECHO Compiling NET Framework 2.0 (64-bit)>>"%~dp0mount\Windows\ngen.cmd"
echo "%%windir%%\Microsoft.NET\Framework64\v2.0.50727\ngen.exe" executeQueuedItems ^>NUL 2^>NUL>>"%~dp0mount\Windows\ngen.cmd"
echo :noNET20x64>>"%~dp0mount\Windows\ngen.cmd"
echo if not exist "%%windir%%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" goto noNET40x86>>"%~dp0mount\Windows\ngen.cmd"
echo ECHO Compiling NET Framework 4.0 (32-bit)>>"%~dp0mount\Windows\ngen.cmd"
echo "%%windir%%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" executeQueuedItems ^>NUL 2^>NUL>>"%~dp0mount\Windows\ngen.cmd"
echo :noNET40x86>>"%~dp0mount\Windows\ngen.cmd"
echo if not exist "%%windir%%\Microsoft.NET\Framework64\v4.0.30319\ngen.exe" goto noNET40x64>>"%~dp0mount\Windows\ngen.cmd"
echo ECHO Compiling NET Framework 4.0 (64-bit)>>"%~dp0mount\Windows\ngen.cmd"
echo "%%windir%%\Microsoft.NET\Framework64\v4.0.30319\ngen.exe" executeQueuedItems ^>NUL 2^>NUL>>"%~dp0mount\Windows\ngen.cmd"
echo :noNET40x64>>"%~dp0mount\Windows\ngen.cmd"
echo exit>>"%~dp0mount\Windows\ngen.cmd"

ECHO.
ECHO.
ECHO ================================================================
echo Unmounting Registry....
ECHO ================================================================
ECHO.

reg unload HKLM\TK_DEFAULT >nul
reg unload HKLM\TK_NTUSER >nul
reg unload HKLM\TK_SOFTWARE >nul
reg unload HKLM\TK_SYSTEM >nul

ECHO.
ECHO.
ECHO ================================================================
echo Adding default app associations settings...
ECHO ================================================================
ECHO.


%DISM% /English /Image:"%~dp0mount" /Import-DefaultAppAssociations:"%~dp0hotfixes\AppAssociations.xml"



:: ============================================================================================================
:: -------------- End of Tweaks Section -----------------------------------------------------------------------
:: ============================================================================================================


ECHO.
ECHO.
ECHO ================================================================
ECHO Unounting image Install.wim
ECHO ================================================================
ECHO.
"%DISM%" /English /Unmount-Wim /MountDir:"%~dp0mount" /commit

ECHO.
ECHO.
ECHO ================================================================
ECHO Repacking file install.wim
ECHO ================================================================
ECHO.
"%DISM%" /English /Export-Image /SourceImageFile:"%~dp0DVD\sources\install.wim" /SourceIndex:1 /DestinationImageFile:"%~dp0DVD\sources\install_temp.wim" /Compress:max /CheckIntegrity
move /y "%~dp0DVD\sources\install_temp.wim" "%~dp0DVD\sources\install.wim" >NUL


if not "%SplitInstallWim%"=="1" goto SkipSplitInstallWim

FOR /F "usebackq" %%A IN ('%~dp0DVD\sources\install.wim') DO set "InstallWimSize=%%~zA"
if "%InstallWimSize%" LSS "4294967296" goto SkipSplitInstallWim

ECHO.
ECHO.
ECHO ================================================================
ECHO Splitting file install.wim
ECHO ================================================================
ECHO.

"%DISM%" /Split-Image /ImageFile:"%~dp0DVD\sources\install.wim" /SWMFile:"%~dp0DVD\sources\install.swm" /FileSize:3700
del /q /f "%~dp0DVD\sources\install.wim" >nul 2>&1

:SkipSplitInstallWim


if "%CreateISO%"=="0" goto dontCreateISO

ECHO.
ECHO.
ECHO ================================================================
ECHO Creating new DVD image
ECHO ================================================================
ECHO.

"%~dp0tools\%HostArchitecture%\oscdimg.exe" -bootdata:2#p0,e,b"%~dp0DVD\boot\etfsboot.com"#pEF,e,b"%~dp0DVD\efi\microsoft\boot\Efisys.bin" -h -m -u2 -udfver102 "%~dp0DVD" "%~dp0Windows10_%ImageArchitecture%_%ImageLanguage%.iso" -lWin10

REM Clean DVD directory
rd /s /q "%~dp0DVD" >nul 2>&1
mkdir "%~dp0DVD" >nul 2>&1

:dontCreateISO


ECHO.
ECHO.
ECHO.
ECHO All finished.
ECHO.
ECHO Press any key to end the script.
ECHO.
PAUSE >NUL


:end
