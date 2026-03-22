@echo off
REM Script para ejecutar análisis de SonarQube en Windows
REM Requiere: sonar-scanner instalado y en PATH
REM           SonarQube servidor corriendo en http://localhost:9000

setlocal enabledelayedexpansion

echo ========================================
echo  HMED - Análisis de Código con SonarQube
echo ========================================
echo.

REM Verificar si sonar-scanner está instalado
where sonar-scanner >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] sonar-scanner no encontrado en PATH
    echo.
    echo Instalar sonar-scanner:
    echo 1. Descargar: https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/
    echo 2. Extraer el archivo
    echo 3. Agregar a PATH: C:\sonar-scanner\bin
    echo.
    pause
    exit /b 1
)

echo [✓] sonar-scanner encontrado
echo.

REM Verificar conexión a SonarQube
echo [*] Verificando conexión a SonarQube...
curl -s http://localhost:9000/api/system/health > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] No se puede conectar a SonarQube en http://localhost:9000
    echo.
    echo Asegúrate de que SonarQube está ejecutándose:
    echo   docker-compose up -d sonarqube
    echo.
    pause
    exit /b 1
)

echo [✓] SonarQube está activo
echo.

REM Ejecutar análisis completo
echo [*] Iniciando análisis del proyecto...
echo.

sonar-scanner ^
    -Dsonar.projectBaseDir=. ^
    -Dsonar.host.url=http://localhost:9000 ^
    -Dsonar.login=admin ^
    -Dsonar.password=20394117Tkd+

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] El análisis falló
    pause
    exit /b 1
)

echo.
echo ========================================
echo  ✓ Análisis completado exitosamente
echo ========================================
echo.
echo Resultados disponibles en:
echo   http://localhost:9000/projects
echo.
pause
