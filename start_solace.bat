@echo off
set LOGFILE=%USERPROFILE%\solace_startup.log
echo [%date% %time%] Starting Solace system... >> %LOGFILE%

:: Wait for Docker to be ready
:wait_docker
docker info >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] Waiting for Docker... >> %LOGFILE%
    timeout /t 10 >nul
    goto wait_docker
)

:: Wait for Internet (optional)
:wait_net
ping -n 2 google.com >nul
if errorlevel 1 (
    echo [%date% %time%] Waiting for internet... >> %LOGFILE%
    timeout /t 10 >nul
    goto wait_net
)

:: Launch Solace containers
cd "C:\Users\diego\OneDrive\Documents\ai_assistant_system"
docker compose --profile core --profile ai --profile support --profile optional up -d >> %LOGFILE% 2>&1
if errorlevel 1 (
    echo [%date% %time%] ❌ Failed to launch Solace containers. >> %LOGFILE%
    exit /b 1
)

echo [%date% %time%] ✅ Solace system launched successfully. >> %LOGFILE%
