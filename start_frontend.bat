@echo off
setlocal enableextensions enabledelayedexpansion

set ROOT=%~dp0
set FRONTEND_DIR=%ROOT%frontend

if not exist "%FRONTEND_DIR%\package.json" (
  echo Frontend not found: "%FRONTEND_DIR%\package.json"
  exit /b 1
)

pushd "%FRONTEND_DIR%"

if not exist "node_modules\" (
  echo Installing dependencies...
  npm install
  if %ERRORLEVEL% neq 0 (
    popd
    exit /b %ERRORLEVEL%
  )
)

echo Starting frontend dev server...
npm run dev

popd
exit /b 0
