@echo off
rem Verin Legal - build and deploy from this folder.
rem Double-click this file (or run deploy.bat in Command Prompt). It always
rem works from the folder it sits in, so there is no "cd" to get wrong.
rem Everything is written to deploy-all-log.txt next to this file.
rem
rem   deploy.bat              web app, demo + summary functions, rules
rem   deploy.bat hosting      web app only

setlocal
cd /d "%~dp0"
set LOG=%~dp0deploy-all-log.txt
set FUNCTIONS_DISCOVERY_TIMEOUT=60
set TARGETS=functions:functions:summarizeThread,functions:functions:seedDemoWorkspace,firestore:rules,hosting
if /i "%~1"=="hosting" set TARGETS=hosting

echo Verin Legal deploy  %date% %time% > "%LOG%"
echo Folder: %cd% >> "%LOG%"
where git >nul 2>&1 && (git rev-parse --abbrev-ref HEAD >> "%LOG%" 2>&1 & git log -1 --oneline >> "%LOG%" 2>&1)

if not exist pubspec.yaml (
  echo pubspec.yaml is not in this folder - put deploy.bat in the project folder. >> "%LOG%"
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
pause
exit /b 0

:failed
echo. >> "%LOG%"
echo ===== FAILED ===== >> "%LOG%"
echo.
echo Something failed. Send deploy-all-log.txt to Claude: %LOG%
pause
exit /b 1
