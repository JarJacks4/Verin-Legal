@echo off
rem Verin Legal - build and deploy from this folder.
rem Double-click this file (or run deploy.bat in Command Prompt). It always
rem works from the folder it sits in, so there is no "cd" to get wrong.
rem Everything is written to deploy-all-log.txt next to this file, and the
rem log is pushed to the deploy-logs branch on GitHub so Claude can read it.
rem
rem   deploy.bat              web app, demo + summary functions, rules
rem   deploy.bat hosting      web app only

setlocal
cd /d "%~dp0"
rem Not inside the project? Find it in Downloads: the folder that has
rem pubspec.yaml, firebase\firebase.json and .git (the GitHub Desktop copy).
if not exist pubspec.yaml (
  echo Looking for the Verin Legal project in Downloads...
  for /f "delims=" %%p in ('dir /s /b "%USERPROFILE%\Downloads\pubspec.yaml" 2^>nul') do (
    if exist "%%~dpp.git" if exist "%%~dppfirebase\firebase.json" if exist "%%~dpplib\verin_app" set "PROJ=%%~dpp"
  )
)
if defined PROJ cd /d "%PROJ%"
set "LOG=%cd%\deploy-all-log.txt"
set FUNCTIONS_DISCOVERY_TIMEOUT=60
set TARGETS=functions:functions:onUserDeleted,functions:functions:ingestScreenshot,functions:functions:extractThreadMessages,functions:functions:verifyMatterChain,functions:functions:setupAccount,functions:functions:deleteAccount,functions:functions:onReceiptWritten,functions:functions:onMatterNamesChanged,functions:functions:refreshMatterRecord,functions:functions:summarizeThread,functions:functions:produceExhibits,functions:functions:clioAuthStart,functions:functions:clioOAuthCallback,functions:functions:clioDisconnect,functions:functions:clioSearchMatters,functions:functions:clioLinkMatter,functions:functions:clioPushDocument,functions:functions:exportMatterRecord,functions:functions:ingestEvidence,functions:functions:onReceiptCreated,functions:functions:reprocessReceipt,functions:functions:exportRecordZip,functions:functions:exportFirmData,functions:functions:exportIntegrationReport,functions:functions:deliverMatterRecord,functions:functions:confirmDelivery,functions:functions:autoDeliverToClio,functions:functions:setBaselineRecordLag,functions:functions:importClosedMatter,functions:functions:standingRecordCounts,functions:functions:exportRecordLagAudit,functions:functions:exportPracticePacket,functions:functions:buildMatterDigest,functions:functions:weeklyMatterDigests,functions:functions:exportFirmMonthlyReport,functions:functions:monthlyFirmReports,functions:functions:exportStandingRecordDocx,functions:functions:deleteDemoMatter,functions:functions:weeklyCostToServe,functions:functions:costToServeNow,functions:functions:approveQuarantined,functions:functions:assignUnrouted,functions:functions:seedDemoWorkspace,functions:functions:demoSimulateArrival,functions:functions:nightlyFirestoreBackup,firestore:rules,firestore:indexes,hosting
if /i "%~1"=="hosting" set TARGETS=hosting

echo Verin Legal deploy  %date% %time% > "%LOG%"
echo Folder: %cd% >> "%LOG%"
where git >nul 2>&1 && (git rev-parse --abbrev-ref HEAD >> "%LOG%" 2>&1 & git log -1 --oneline >> "%LOG%" 2>&1)

if not exist pubspec.yaml (
  echo Could not find the project: no folder in Downloads has pubspec.yaml, firebase\firebase.json and .git. >> "%LOG%"
  goto :failed
)

echo.
echo [1/3] Installing backend packages...
echo. >> "%LOG%"
echo ===== 1/3 npm install ===== >> "%LOG%"
pushd firebase\functions
call npm install --no-audit --no-fund >> "%LOG%" 2>&1
set ERR=%errorlevel%
popd
if not "%ERR%"=="0" goto :failed

echo [2/3] Building the web app (a few minutes)...
echo. >> "%LOG%"
echo ===== 2/3 flutter build web ===== >> "%LOG%"
call flutter build web --release --output firebase/public >> "%LOG%" 2>&1
if errorlevel 1 goto :failed

echo [3/3] Deploying to Firebase...
echo. >> "%LOG%"
echo ===== 3/3 firebase deploy (%TARGETS%) ===== >> "%LOG%"
pushd firebase
call firebase deploy --only %TARGETS% --project verin-legal-fbzp5w >> "%LOG%" 2>&1
set ERR=%errorlevel%
popd
if not "%ERR%"=="0" goto :failed

echo. >> "%LOG%"
echo ===== DONE ===== >> "%LOG%"
echo.
echo Done. Log: %LOG%
call :pushlog
pause
exit /b 0

:failed
echo. >> "%LOG%"
echo ===== FAILED ===== >> "%LOG%"
echo.
echo Something failed. Log: %LOG%
call :pushlog
pause
exit /b 1

:pushlog
rem Puts the log on the deploy-logs branch without touching your files or
rem your current branch (uses a temporary git index).
where git >nul 2>&1 || (echo Git is not on PATH - send deploy-all-log.txt to Claude instead. & exit /b 0)
set GIT_INDEX_FILE=%TEMP%\verin-deploy-log.index
if exist "%GIT_INDEX_FILE%" del "%GIT_INDEX_FILE%"
set BLOB=
set TREE=
set COMMIT=
for /f "delims=" %%h in ('git hash-object -w "%LOG%"') do set BLOB=%%h
git update-index --add --cacheinfo 100644 %BLOB% deploy-all-log.txt
for /f "delims=" %%t in ('git write-tree') do set TREE=%%t
set GIT_INDEX_FILE=
for /f "delims=" %%c in ('git commit-tree %TREE% -m "Deploy log %date% %time%"') do set COMMIT=%%c
if "%COMMIT%"=="" (echo Could not save the log to git - send deploy-all-log.txt to Claude instead. & exit /b 0)
git push -q -f origin %COMMIT%:refs/heads/deploy-logs >nul 2>&1
if errorlevel 1 (echo Could not push the log - send deploy-all-log.txt to Claude instead.) else (echo Log sent to GitHub - tell Claude to check it.)
exit /b 0
