@echo off
REM === Solace Full System Launcher (corrected) ===

cd /d %~dp0
echo Starting all services...

docker-compose -f "%cd%\\solace-docker-compose.yml" --env-file "%cd%\\.env.solace" up -d --build

echo.
echo ✅ All services started successfully.
echo Visit your dashboards:
echo  - Solace: http://localhost:5000
echo  - WebUI:  http://localhost:3000
echo  - Jupyter: http://localhost:8888
pause
