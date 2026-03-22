@echo off
REM Script para descargar reporte de SonarQube via API
REM Ejecuta el script PowerShell con los permisos necesarios

setlocal enabledelayedexpansion

echo ========================================
echo  HMED - Exportar Reporte de SonarQube
echo ========================================
echo.

REM Ejecutar script PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0export-sonar-report.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] El export falló
    pause
    exit /b 1
)

pause
