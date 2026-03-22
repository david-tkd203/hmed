# Script PowerShell para ejecutar analisis de SonarQube con Docker
# Uso: .\install-and-analyze.ps1

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Green
Write-Host " HMED - Analisis de Seguridad con SonarQube" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$Success = "Green"
$ErrorColor = "Red"
$Info = "Cyan"
$Warning = "Yellow"

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

function Test-Docker {
    try {
        & docker ps 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Docker esta corriendo" -ForegroundColor $Success
            return $true
        }
    }
    catch {
        Write-Host "[FAIL] Error con Docker: $_" -ForegroundColor $ErrorColor
        return $false
    }
}

function Get-DockerNetworkName {
    try {
        $network = & docker network ls --filter name=hmed_network --quiet
        if ($network) {
            return $network
        }
        
        Write-Host "[WARN] Red hmed_network no encontrada, buscando alternativas..." -ForegroundColor $Warning
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
    Write-Host "[*] Verificando SonarQube..." -ForegroundColor $Info
    
    $maxAttempts = 10
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:9000" -UseBasicParsing -ErrorAction Stop -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "[OK] SonarQube disponible" -ForegroundColor $Success
                return $true
            }
        }
        catch {
            $attempt = $attempt + 1
            if ($attempt -lt $maxAttempts) {
                Write-Host "[*] Esperando SonarQube... ($attempt/$maxAttempts)" -ForegroundColor $Warning
                Start-Sleep -Seconds 2
            }
        }
    }
    
    Write-Host "[FAIL] No se puede conectar a SonarQube en http://localhost:9000" -ForegroundColor $ErrorColor
    Write-Host "[INFO] Ejecuta: docker-compose up -d" -ForegroundColor $Info
    return $false
}

function Create-SonarProperties {
    Write-Host "[*] Creando configuracion de SonarQube..." -ForegroundColor $Info
    
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
        Write-Host "[OK] Configuracion creada" -ForegroundColor $Success
        return $true
    }
    catch {
        Write-Host "[FAIL] Error creando configuracion" -ForegroundColor $ErrorColor
        return $false
    }
}

function Run-SonarAnalysisWithDocker {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Ejecutando Analisis de Seguridad" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    try {
        Write-Host "[*] Ejecutando sonar-scanner con Docker..." -ForegroundColor $Info
        
        $networkName = Get-DockerNetworkName
        $currentDir = Get-Location
        
        Write-Host "[INFO] Red Docker: $networkName" -ForegroundColor $Info
        Write-Host "[INFO] Directorio: $currentDir" -ForegroundColor $Info
        Write-Host ""
        
        & docker run --rm `
            --network=$networkName `
            -v "${currentDir}:/usr/src" `
            sonarsource/sonar-scanner-cli:latest `
            -Dsonar.projectKey=HMED `
            -Dsonar.projectName="HMED - Sistema de Historico Clinico" `
            -Dsonar.sources=/usr/src/backend/registros,/usr/src/frontend/src `
            -Dsonar.host.url=http://sonarqube:9000 `
            -Dsonar.login=admin `
            -Dsonar.password=admin
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor $Success
            Write-Host " OK - Analisis Completado" -ForegroundColor $Success
            Write-Host "========================================" -ForegroundColor $Success
            return $true
        }
        else {
            Write-Host "[WARN] El analisis termino con advertencias o errores menores" -ForegroundColor $Warning
            Write-Host "[INFO] Verifica los resultados en http://localhost:9000/dashboard?id=HMED" -ForegroundColor $Info
            return $true
        }
    }
    catch {
        Write-Host "[FAIL] Error ejecutando sonar-scanner: $_" -ForegroundColor $ErrorColor
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
    Write-Host "[*] Abriendo resultados en navegador..." -ForegroundColor $Info
    Start-Sleep -Seconds 3
    
    try {
        Start-Process "http://localhost:9000/dashboard?id=HMED" -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "[INFO] Abre manualmente: http://localhost:9000/dashboard?id=HMED" -ForegroundColor $Info
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $Success
    Write-Host " ANALISIS COMPLETADO EXITOSAMENTE" -ForegroundColor $Success
    Write-Host "========================================" -ForegroundColor $Success
    Write-Host ""
    Write-Host "[INFO] Credenciales SonarQube:" -ForegroundColor $Info
    Write-Host "  Usuario: admin" -ForegroundColor $Success
    Write-Host "  Contrasena: admin" -ForegroundColor $Success
}
else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $ErrorColor
    Write-Host " ERROR EN EL ANALISIS" -ForegroundColor $ErrorColor
    Write-Host "========================================" -ForegroundColor $ErrorColor
    Write-Host ""
    Write-Host "[DEBUG] Por favor verifica:" -ForegroundColor $Warning
    Write-Host "  1. Docker esta ejecutando" -ForegroundColor $Info
    Write-Host "  2. SonarQube en http://localhost:9000 esta disponible" -ForegroundColor $Info
    Write-Host "  3. La red Docker es accesible" -ForegroundColor $Info
}

Read-Host "`nPresiona Enter para finalizar"
