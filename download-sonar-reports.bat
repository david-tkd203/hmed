@echo off
REM Script wrapper para descargar reportes de SonarQube

setlocal enabledelayedexpansion
cls

echo.
echo ========================================
echo  Descargando Reportes de SonarQube
echo ========================================
echo.

echo Iniciando descarga...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0export-sonar-report.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] La descarga termino con errores
    pause
    exit /b 1
)

echo.
echo [OK] Descarga completada exitosamente
echo.

pause
