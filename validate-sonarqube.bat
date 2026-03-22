@echo off
REM Script para validar el ambiente de SonarQube antes del analisis
REM Uso: validate-sonarqube.bat

echo ========================================
echo  Validando Ambiente para SonarQube
echo ========================================
echo.

setlocal enabledelayedexpansion

REM Verificar que estamos en el directorio correcto
if not exist "docker-compose.yml" (
    echo [FAIL] docker-compose.yml no encontrado
    echo [INFO] Ejecuta este script desde la carpeta raiz del proyecto
    echo.
    pause
    exit /b 1
)

echo [OK] directorio correcto

REM Verificar Docker
echo [*] Verificando Docker...
docker ps >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Docker no esta disponible
    echo [INFO] Inicia Docker Desktop o asegúrate que Docker está corriendo
    echo.
    pause
    exit /b 1
)
echo [OK] Docker disponible

REM Verificar contenedores
echo [*] Verificando contenedores...
docker-compose ps | findstr sonarqube >nul 2>&1
if errorlevel 1 (
    echo [FAIL] SonarQube no está en docker-compose
    echo [INFO] Ejecuta: docker-compose up -d
    echo.
    pause
    exit /b 1
)
echo [OK] SonarQube en docker-compose

REM Verificar conectividad a SonarQube
echo [*] Verificando conectividad a SonarQube...
for /l %%i in (1,1,10) do (
    powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:9000' -UseBasicParsing -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] SonarQube accesible
        goto :sonarqube_ok
    )
    echo [*] Esperando SonarQube... %%i/10
    timeout /t 2 /nobreak >nul 2>&1
)
echo [FAIL] No se puede conectar a SonarQube
echo [INFO] Verifica: docker-compose logs sonarqube
pause
exit /b 1

:sonarqube_ok

REM Verificar sonar-scanner
echo [*] Verificando sonar-scanner...
if exist "C:\sonar-scanner\bin\sonar-scanner.bat" (
    echo [OK] sonar-scanner instalado
) else (
    echo [WARN] sonar-scanner no instalado
    echo [INFO] Se instalará automáticamente durante el analisis
)

REM Verificar archivos del proyecto
echo [*] Verificando archivos del proyecto...
if exist "backend" (
    echo [OK] Directorio backend encontrado
) else (
    echo [WARN] Directorio backend no encontrado
)

if exist "frontend" (
    echo [OK] Directorio frontend encontrado
) else (
    echo [WARN] Directorio frontend no encontrado
)

REM Verificar espacio en disco
echo [*] Verificando espacio en disco...
powershell -Command "$disk = Get-Volume -DriveLetter C; $free = [math]::Round($disk.SizeRemaining / 1GB); if ($free -lt 1) { exit 1 } else { exit 0 }" >nul 2>&1
if errorlevel 1 (
    echo [WARN] Poco espacio disponible en disco C:
    echo [INFO] Se requieren al menos 1 GB para sonar-scanner
) else (
    echo [OK] Espacio en disco suficiente
)

echo.
echo ========================================
echo  Validacion Completada
echo ========================================
echo.
echo [OK] Todo parece estar correctamente configurado
echo [INFO] Ejecuta: .\start-security-analysis.bat
echo.
pause
