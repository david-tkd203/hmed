@echo off
REM Script para ejecutar análisis SonarQB en Windows
REM Uso: run-sonar-analysis.bat [TOKEN]

setlocal enabledelayedexpansion

set "SONAR_TOKEN=%1"
if "!SONAR_TOKEN!"=="" (
    set "SONAR_TOKEN=sqa_6610dc854e1e84abbfa0bd6f21afa3c277907eb4"
)

echo 🔍 Iniciando análisis SonarQB...
echo 🔐 Token: !SONAR_TOKEN:~0,10!...***
echo.

cd /d "%~dp0"

echo 📊 Analizando código...
echo    Proyecto: historico-clinico
echo    Fuentes: backend/registros, frontend/src
echo.

docker run --rm ^
  --network=historicoclinico_hmed_network ^
  -v "%cd%:/usr/src" ^
  sonarsource/sonar-scanner-cli:latest ^
  -Dsonar.projectKey=historico-clinico ^
  -Dsonar.sources=/usr/src/backend/registros,/usr/src/frontend/src ^
  -Dsonar.host.url=http://sonarqube:9000 ^
  -Dsonar.token=!SONAR_TOKEN!

echo.
echo ✅ Análisis completado
echo.
echo 📈 Abriendo dashboard: http://localhost:9000
echo    Proyecto: 'Histórico Clínico - Sistema Médico'
echo.
echo Métricas disponibles:
echo   🔴 Bugs - Errores reales de código
echo   🟡 Code Smells - Malas prácticas
echo   🔐 Security - Vulnerabilidades
echo   📊 Deuda Técnica - Horas para arreglarlo
echo.

pause
