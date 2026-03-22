@echo off
REM Script para ejecutar análisis de SonarQube con instalación automática de sonar-scanner
REM Este script corre automáticamente install-and-analyze.ps1

setlocal enabledelayedexpansion

echo ========================================
echo  HMED - Análisis de Seguridad con SonarQube
echo ========================================
echo.

REM Ejecutar el script PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-and-analyze.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] El script falló
    pause
    exit /b 1
)

pause
