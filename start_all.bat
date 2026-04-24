@echo off
setlocal enableextensions enabledelayedexpansion
set ROOT=%~dp0
set FRONTEND_DIR=%ROOT%frontend
set BACKEND_DIR=%ROOT%backend
set DRYRUN=0
rem fallback: support 'back' directory as backend if 'backend' not found
if not exist "%BACKEND_DIR%" (
  if exist "%ROOT%back" (
    set BACKEND_DIR=%ROOT%back
  )
)
if /I "%~1"=="dry-run" set DRYRUN=1
if exist "%COMPOSE_FILE%" (
  if "%DRYRUN%"=="1" (
    echo docker compose -f "%COMPOSE_FILE%" up -d
  ) else (
    pushd "%ROOT%"
    docker compose up -d
    if %ERRORLEVEL% neq 0 docker-compose up -d
    popd
  )
 ) else (
  echo No docker-compose.yml, skip database
)
if exist "%BACKEND_DIR%" (
  if exist "%BACKEND_DIR%\package.json" (
    if "%DRYRUN%"=="1" (
      echo start "Backend(Node)" cmd /c "cd /d ""%BACKEND_DIR%"" && npm run dev || npm start"
    ) else (
      start "Backend(Node)" cmd /c "cd /d ""%BACKEND_DIR%"" && npm run dev || npm start"
    )
  ) else if exist "%BACKEND_DIR%\pom.xml" (
    if "%DRYRUN%"=="1" (
      echo start "Backend(Maven)" cmd /c "cd /d ""%BACKEND_DIR%"" && mvn spring-boot:run"
    ) else (
      start "Backend(Maven)" cmd /c "cd /d ""%BACKEND_DIR%"" && mvn spring-boot:run"
    )
  ) else if exist "%BACKEND_DIR%\gradlew.bat" (
    if "%DRYRUN%"=="1" (
      echo start "Backend(Gradle)" cmd /c "cd /d ""%BACKEND_DIR%"" && gradlew.bat bootRun"
    ) else (
      start "Backend(Gradle)" cmd /c "cd /d ""%BACKEND_DIR%"" && gradlew.bat bootRun"
    )
  ) else if exist "%BACKEND_DIR%\build.gradle" (
    if "%DRYRUN%"=="1" (
      echo start "Backend(Gradle)" cmd /c "cd /d ""%BACKEND_DIR%"" && gradle bootRun"
    ) else (
      start "Backend(Gradle)" cmd /c "cd /d ""%BACKEND_DIR%"" && gradle bootRun"
    )
  ) else (
    echo Backend directory exists but no recognized start script
  )
 ) else (
  echo No backend directory, skip backend
)
if exist "%FRONTEND_DIR%\package.json" (
  if "%DRYRUN%"=="1" (
    echo start "Frontend" cmd /c "cd /d ""%FRONTEND_DIR%"" && npm run dev"
  ) else (
    start "Frontend" cmd /c "cd /d ""%FRONTEND_DIR%"" && npm run dev"
  )
 ) else (
  echo No frontend package.json, skip frontend
)
exit /b 0
