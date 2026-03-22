@echo off
REM Script para descargar manualmente sonar-scanner
REM Uso: download-sonar-scanner.bat

setlocal enabledelayedexpansion

echo ========================================
echo  Descargando SonarScanner 4.8.0.3345
echo ========================================
echo.

REM Crear directorio si no existe
if not exist "C:\sonar-scanner-dl" (
    mkdir C:\sonar-scanner-dl
    echo [OK] Directorio creado: C:\sonar-scanner-dl
)

REM Intentar descargar con PowerShell
echo [*] Intentando descarga con PowerShell...
powershell -NoProfile -Command ^
"$url = 'https://github.com/SonarSource/sonar-scanner-cli/releases/download/4.8.0.3345/sonar-scanner-cli-4.8.0.3345-windows-x86_64.zip'; " ^
"$output = 'C:\sonar-scanner-dl\sonar-scanner.zip'; " ^
"$headers = @{'User-Agent' = 'Mozilla/5.0'}; " ^
"try { " ^
"  Write-Host '[*] Descargando desde GitHub...' -ForegroundColor Cyan; " ^
"  Invoke-WebRequest -Uri $url -OutFile $output -Headers $headers -UseBasicParsing -ErrorAction Stop; " ^
"  Write-Host '[OK] Descarga completada' -ForegroundColor Green; " ^
"  exit 0; " ^
"} catch { " ^
"  Write-Host '[FAIL] Error: ' $_.Exception.Message -ForegroundColor Red; " ^
"  exit 1; " ^
"}" >nul 2>&1

if errorlevel 1 (
    echo [FAIL] Error con PowerShell
    echo.
    echo [OPCION 1] Descargar manualmente:
    echo  1. Abre este URL en tu navegador:
    echo     https://github.com/SonarSource/sonar-scanner-cli/releases/download/4.8.0.3345/sonar-scanner-cli-4.8.0.3345-windows-x86_64.zip
    echo  2. Guarda el archivo como: C:\sonar-scanner-dl\sonar-scanner.zip
    echo  3. Luego ejecuta: extract-sonar-scanner.bat
    echo.
    echo [OPCION 2] Usar curl (si está instalado):
    echo  curl -L -o C:\sonar-scanner-dl\sonar-scanner.zip ^
    echo    https://github.com/SonarSource/sonar-scanner-cli/releases/download/4.8.0.3345/sonar-scanner-cli-4.8.0.3345-windows-x86_64.zip
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Extrayendo archivos...
echo ========================================
echo.

powershell -NoProfile -Command ^
"try { " ^
"  Write-Host '[*] Extrayendo...' -ForegroundColor Cyan; " ^
"  Expand-Archive -Path 'C:\sonar-scanner-dl\sonar-scanner.zip' -DestinationPath 'C:\sonar-scanner-dl' -Force -ErrorAction Stop; " ^
"  Write-Host '[OK] Archivos extraidos' -ForegroundColor Green; " ^
"  exit 0; " ^
"} catch { " ^
"  Write-Host '[FAIL] Error: ' $_.Exception.Message -ForegroundColor Red; " ^
"  exit 1; " ^
"}" >nul 2>&1

if errorlevel 1 (
    echo [FAIL] Error al extraer
    pause
    exit /b 1
)

REM Buscar la carpeta extraida y mover los archivos
for /d %%D in (C:\sonar-scanner-dl\sonar-scanner*) do (
    echo [*] Moviendo archivos desde %%D...
    
    if exist "C:\sonar-scanner" (
        echo [*] Eliminando instalacion anterior...
        rmdir /s /q C:\sonar-scanner >nul 2>&1
    )
    
    ren "%%D" sonar-scanner >nul 2>&1
    
    if exist "C:\sonar-scanner-dl\sonar-scanner\bin\sonar-scanner.bat" (
        echo [OK] Estructura correcta verificada
        goto :install_done
    )
)

:install_done

REM Copiar a la ubicacion final
echo [*] Finalizando instalacion...
move C:\sonar-scanner-dl\sonar-scanner C:\sonar-scanner >nul 2>&1

if exist "C:\sonar-scanner\bin\sonar-scanner.bat" (
    echo.
    echo ========================================
    echo  INSTALACION COMPLETADA
    echo ========================================
    echo.
    echo [OK] SonarScanner instalado en: C:\sonar-scanner
    echo [OK] Puedes ejecutar: .\start-security-analysis.bat
    echo.
) else (
    echo.
    echo [FAIL] No se encontro sonar-scanner.bat en la estructura esperada
    echo [INFO] Verifica: C:\sonar-scanner\bin\sonar-scanner.bat
    echo.
)

REM Limpiar directorio temporal
rmdir /s /q C:\sonar-scanner-dl >nul 2>&1

pause
