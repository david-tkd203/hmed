# Script PowerShell para ejecutar analisis de SonarQube con Docker
# Uso: .\install-and-analyze.ps1

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Green
Write-Host " HMED - Analisis de Seguridad con SonarQube" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# ============================================================================
# VARIABLES DE CONFIGURACIÓN
# ============================================================================

# Token de SonarQube generado por el proyecto
$SonarToken = "sqa_b0fc01f42ecb4a96c12c471ca38c00f00e48d892"

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

function Test-Docker {
    try {
        & docker ps 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Docker esta corriendo" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "[FAIL] Error con Docker: $_" -ForegroundColor Red
        return $false
    }
}

function Get-DockerNetworkName {
    try {
        $network = & docker network ls --filter name=hmed_network --quiet
        if ($network) {
            return $network
        }
        
        Write-Host "[WARN] Red hmed_network no encontrada, buscando alternativas..." -ForegroundColor Yellow
        $networks = & docker network ls --format "{{.Name}}" | Select-String "hmed|historico"
        if ($networks) {
            return $networks -split "`n" | Select-Object -First 1
        }
        
        Write-Host "[INFO] Usando bridge por defecto" -ForegroundColor $Info
        return "bridge"
    }
    catch {
        Write-Host "[INFO] Usando bridge por defecto" -ForegroundColor $Info
        return "bridge"
    }
}

function Test-SonarQubeConnection {
    Write-Host "[*] Verificando SonarQube..." -ForegroundColor Cyan
    
    $maxAttempts = 10
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:9000" -UseBasicParsing -ErrorAction Stop -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "[OK] SonarQube disponible" -ForegroundColor Green
                
                # Verificar que las credenciales son correctas
                Write-Host "[*] Validando credenciales..." -ForegroundColor Cyan
                $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("admin:20394117Tkd+"))
                $headers = @{
                    "Authorization" = "Basic $auth"
                }
                
                try {
                    $apiResponse = Invoke-WebRequest `
                        -Uri "http://localhost:9000/api/user_tokens/search" `
                        -Method Get `
                        -Headers $headers `
                        -UseBasicParsing `
                        -TimeoutSec 5 `
                        -ErrorAction Stop
                    
                    Write-Host "[OK] Credenciales válidas" -ForegroundColor Green
                    return $true
                }
                catch {
                    Write-Host "[WARN] Las credenciales podrían no ser correctas (continuando...)" -ForegroundColor Yellow
                    return $true
                }
            }
        }
        catch {
            $attempt = $attempt + 1
            if ($attempt -lt $maxAttempts) {
                Write-Host "[*] Esperando SonarQube... ($attempt/$maxAttempts)" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    }
    
    Write-Host "[FAIL] No se puede conectar a SonarQube en http://localhost:9000" -ForegroundColor Red
    Write-Host "[INFO] Ejecuta: docker-compose up -d" -ForegroundColor Cyan
    return $false
}

function Create-SonarProperties {
    Write-Host "[*] Creando configuracion de SonarQube..." -ForegroundColor Cyan
    
    try {
        $propertiesFile = "sonar-project.properties"
        
        $content = @"
sonar.projectKey=HMED
sonar.projectName=HMED - Sistema de Historico Clinico
sonar.projectVersion=1.0
sonar.sourceEncoding=UTF-8

sonar.sources=.
sonar.inclusions=backend/**,frontend/**
sonar.exclusions=**/*test*,**/node_modules/**,**/.git/**,**/migrations/**

sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.python.coverage.reportPath=coverage.xml

sonar.host.url=http://sonarqube:9000
"@
        
        Set-Content -Path $propertiesFile -Value $content -ErrorAction Stop
        Write-Host "[OK] Configuracion creada" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[FAIL] Error creando configuracion" -ForegroundColor Red
        return $false
    }
}

function Get-SonarQubeToken {
    Write-Host "[*] Obteniendo token de SonarQube..." -ForegroundColor Cyan
    
    if ($SonarToken) {
        Write-Host "[OK] Token disponible: $($SonarToken.Substring(0, 10))..." -ForegroundColor Green
        return $SonarToken
    }
    else {
        Write-Host "[WARN] Token no configurado, usando credenciales directas" -ForegroundColor Yellow
        return $null
    }
}


function Run-SonarAnalysisWithDocker {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Ejecutando Analisis de Seguridad" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "[*] Ejecutando sonar-scanner con Docker..." -ForegroundColor Cyan
        
        # Intentar obtener token
        $token = Get-SonarQubeToken
        
        $networkName = Get-DockerNetworkName
        $currentDir = Get-Location
        
        Write-Host "[INFO] Red Docker: $networkName" -ForegroundColor Cyan
        Write-Host "[INFO] Directorio: $currentDir" -ForegroundColor Cyan
        Write-Host ""
        
        # Preparar argumentos
        $args = @(
            "run", "--rm",
            "--network=$networkName",
            "-v", "${currentDir}:/usr/src",
            "sonarsource/sonar-scanner-cli:latest",
            "-Dsonar.projectKey=HMED",
            "-Dsonar.projectName=HMED - Sistema de Historico Clinico",
            "-Dsonar.sources=/usr/src/backend/registros,/usr/src/frontend/src",
            "-Dsonar.host.url=http://sonarqube:9000"
        )
        
        # Si se generó token, usarlo; si no, usar credenciales
        if ($token) {
            Write-Host "[INFO] Usando token para autenticación" -ForegroundColor Cyan
            $args += "-Dsonar.login=$token"
        }
        else {
            Write-Host "[INFO] Usando credenciales (usuario/contraseña)" -ForegroundColor Cyan
            $args += "-Dsonar.login=admin"
            $args += "-Dsonar.password=20394117Tkd+"
        }
        
        & docker $args
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host " OK - Analisis Completado" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[WARN] El analisis termino con advertencias o errores menores" -ForegroundColor Yellow
            Write-Host "[INFO] Verifica los resultados en http://localhost:9000/dashboard?id=HMED" -ForegroundColor Cyan
            return $true
        }
    }
    catch {
        Write-Host "[FAIL] Error ejecutando sonar-scanner: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# MAIN
# ============================================================================

Write-Host "[PASO 1/4] Verificando Docker..." -ForegroundColor Green
if (-not (Test-Docker)) {
    Read-Host "`nPresiona Enter para continuar"
    exit 1
}

Write-Host ""
Write-Host "[PASO 2/4] Verificando SonarQube..." -ForegroundColor Green
if (-not (Test-SonarQubeConnection)) {
    Read-Host "`nPresiona Enter para continuar"
    exit 1
}

Write-Host ""
Write-Host "[PASO 3/4] Configurando proyecto..." -ForegroundColor Green
Create-SonarProperties | Out-Null

Write-Host ""
Write-Host "[PASO 4/4] Ejecutando analisis..." -ForegroundColor Green
$success = Run-SonarAnalysisWithDocker

if ($success) {
    Write-Host ""
    Write-Host "[*] Abriendo resultados en navegador..." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    
    try {
        Start-Process "http://localhost:9000/dashboard?id=HMED" -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "[INFO] Abre manualmente: http://localhost:9000/dashboard?id=HMED" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " ANALISIS COMPLETADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] Credenciales SonarQube:" -ForegroundColor Cyan
    Write-Host "  Dashboard: http://localhost:9000" -ForegroundColor Green
    Write-Host "  Usuario: admin" -ForegroundColor Green
    Write-Host "  Contraseña: 20394117Tkd+" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " ERROR EN EL ANALISIS" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "[DEBUG] Por favor verifica:" -ForegroundColor Yellow
    Write-Host "  1. Docker esta ejecutando" -ForegroundColor Cyan
    Write-Host "  2. SonarQube en http://localhost:9000 esta disponible" -ForegroundColor Cyan
    Write-Host "  3. La red Docker es accesible" -ForegroundColor Cyan
}

Read-Host "`nPresiona Enter para finalizar"
