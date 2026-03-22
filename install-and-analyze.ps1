# Script PowerShell para analizar con SonarQube
# Uso: .\install-and-analyze.ps1

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$ScriptStartTime = Get-Date
$LogsDirectory = "logs"
$LogFile = Join-Path $LogsDirectory "analysis_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"

if (-not (Test-Path $LogsDirectory)) {
    New-Item -ItemType Directory -Path $LogsDirectory -Force | Out-Null
}

$SonarToken = $env:SONAR_TOKEN
if (-not $SonarToken) {
    Write-Log "ERROR" "SONAR_TOKEN environment variable not set. Please set it before running: `$env:SONAR_TOKEN = 'your-token'"
    exit 1
}

# ============================================================================
# FUNCIONES DE LOGGING
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    $colors = @{
        "SUCCESS" = "Green"
        "ERROR" = "Red"
        "WARNING" = "Yellow"
        "DEBUG" = "Gray"
        "INFO" = "Cyan"
    }
    
    $color = $colors[$Level] 
    if (-not $color) { $color = "White" }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " $Title" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# FUNCIONES DE VERIFICACION
# ============================================================================

function Test-Docker {
    Write-Log "Verificando Docker..." "INFO"
    try {
        $dockerVersion = & docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Docker OK: $dockerVersion" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Log "Error con Docker: $_" "ERROR"
    }
    return $false
}

function Test-SystemRequirements {
    Write-Log "Verificando requisitos del sistema..." "INFO"
    
    $pwVersion = $PSVersionTable.PSVersion.Major
    if ($pwVersion -ge 5) {
        Write-Log "PowerShell 5.0+ OK" "SUCCESS"
        return $true
    } else {
        Write-Log "PowerShell 5.0+ NO ENCONTRADO" "ERROR"
        return $false
    }
}

function Get-DockerNetworkName {
    try {
        Write-Log "Detectando red Docker..." "DEBUG"
        $network = & docker network ls --filter name=hmed_network --quiet 2>$null
        if ($network) {
            Write-Log "Red encontrada: hmed_network" "SUCCESS"
            return $network
        }
        Write-Log "Usando bridge por defecto" "INFO"
        return "bridge"
    }
    catch {
        Write-Log "Error detectando red: $_" "WARNING"
        return "bridge"
    }
}

function Test-SonarQubeConnection {
    Write-Log "Verificando conexion a SonarQube..." "INFO"
    
    $maxAttempts = 10
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:9000" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Log "SonarQube disponible (Status: $($response.StatusCode))" "SUCCESS"
                return $true
            }
        }
        catch {
            $attempt++
            if ($attempt -lt $maxAttempts) {
                Write-Log "Esperando SonarQube... ($attempt/$maxAttempts)" "WARNING"
                Start-Sleep -Seconds 2
            }
        }
    }
    
    Write-Log "No se puede conectar a SonarQube en http://localhost:9000" "ERROR"
    return $false
}

function Create-SonarProperties {
    Write-Log "Creando configuracion de SonarQube..." "INFO"
    
    try {
        $propertiesFile = "sonar-project.properties"
        $content = @"
sonar.projectKey=HMED
sonar.projectName=HMED - Sistema de Historico Clinico
sonar.projectVersion=1.0
sonar.sourceEncoding=UTF-8
sonar.sources=.
sonar.inclusions=backend/**,frontend/**
sonar.exclusions=**/test*,**/node_modules/**,**/.git/**,**/migrations/**,**/dist/**
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.python.coverage.reportPath=coverage.xml
sonar.host.url=http://sonarqube:9000
"@
        
        Set-Content -Path $propertiesFile -Value $content -ErrorAction Stop
        Write-Log "Archivo sonar-project.properties creado" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Error creando configuracion: $_" "ERROR"
        return $false
    }
}

function Get-SonarQubeToken {
    if ($SonarToken) {
        Write-Log "Token disponible: $($SonarToken.Substring(0,10))..." "SUCCESS"
        return $SonarToken
    }
    Write-Log "Token no configurado, usando credenciales" "WARNING"
    return $null
}

function Analyze-CodeStructure {
    Write-Log "Analizando estructura del codigo..." "INFO"
    
    if (Test-Path "backend") {
        $pythonFiles = @(Get-ChildItem -Path "backend" -Filter "*.py" -Recurse -ErrorAction SilentlyContinue).Count
        Write-Log "Backend - Python files: $pythonFiles" "INFO"
    }
    
    if (Test-Path "frontend") {
        $jsFiles = @(Get-ChildItem -Path "frontend/src" -Filter "*.jsx" -Recurse -ErrorAction SilentlyContinue).Count
        Write-Log "Frontend - JSX files: $jsFiles" "INFO"
    }
}

function Run-SonarAnalysisWithDocker {
    Write-Section "Ejecutando Analisis de Seguridad"
    
    $AnalysisStartTime = Get-Date
    Write-Log "Inicio del analisis: $AnalysisStartTime" "INFO"
    
    try {
        $token = Get-SonarQubeToken
        $networkName = Get-DockerNetworkName
        $currentDir = Get-Location
        
        Write-Log "Red Docker: $networkName" "INFO"
        Write-Log "Directorio: $currentDir" "INFO"
        
        $args = @(
            "run", "--rm",
            "--network=$networkName",
            "-v", "${currentDir}:/usr/src",
            "sonarsource/sonar-scanner-cli:latest",
            "-Dsonar.projectKey=HMED",
            "-Dsonar.projectName=HMED",
            "-Dsonar.sources=/usr/src/backend/registros,/usr/src/frontend/src",
            "-Dsonar.host.url=http://sonarqube:9000"
        )
        
        if ($token) {
            Write-Log "Usando token para autenticacion" "INFO"
            $args += "-Dsonar.login=$token"
        } else {
            Write-Log "Usando credenciales (admin)" "INFO"
            $args += "-Dsonar.login=admin"
            $args += "-Dsonar.password=20394117Tkd+"
        }
        
        Write-Log "Ejecutando docker..." "INFO"
        & docker $args 2>&1 | Tee-Object -FilePath $LogFile -Append
        
        $AnalysisEndTime = Get-Date
        $Duration = ($AnalysisEndTime - $AnalysisStartTime).TotalSeconds
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Analisis completado exitosamente (${Duration}s)" "SUCCESS"
            $AnalysisMetrics["Status"] = "SUCCESS"
            $AnalysisMetrics["Duration"] = $Duration
            return $true
        } else {
            Write-Log "El analisis termino con advertencias (${Duration}s)" "WARNING"
            Write-Log "Verifica los resultados en http://localhost:9000/dashboard?id=HMED" "INFO"
            $AnalysisMetrics["Status"] = "COMPLETED_WITH_WARNINGS"
            $AnalysisMetrics["Duration"] = $Duration
            return $true
        }
    }
    catch {
        Write-Log "Error ejecutando analisis: $_" "ERROR"
        $AnalysisMetrics["Status"] = "FAILED"
        return $false
    }
}

function Get-SonarQubeMetrics {
    Write-Log "Recuperando metricas de SonarQube..." "INFO"
    
    try {
        $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("admin:20394117Tkd+"))
        $headers = @{
            "Authorization" = "Basic $auth"
        }
        
        $projectResponse = Invoke-WebRequest `
            -Uri "http://localhost:9000/api/projects/search?q=HMED" `
            -Method Get `
            -Headers $headers `
            -UseBasicParsing `
            -ErrorAction Stop
        
        $projects = $projectResponse.Content | ConvertFrom-Json
        
        if ($projects.components -and $projects.components.Count -gt 0) {
            $project = $projects.components[0]
            Write-Log "Proyecto encontrado: $($project.name)" "SUCCESS"
            
            $qgResponse = Invoke-WebRequest `
                -Uri "http://localhost:9000/api/qualitygates/project_status?projectKey=$($project.key)" `
                -Method Get `
                -Headers $headers `
                -UseBasicParsing `
                -ErrorAction Stop
            
            $qg = $qgResponse.Content | ConvertFrom-Json
            $qgStatus = $qg.projectStatus.status
            
            Write-Log "Quality Gate Status: $qgStatus" "INFO"
            $AnalysisMetrics["QualityGate"] = $qgStatus
            return $true
        } else {
            Write-Log "Proyecto HMED no encontrado aun (procesando...)" "WARNING"
            return $false
        }
    }
    catch {
        Write-Log "Error recuperando metricas: $_" "WARNING"
        return $false
    }
}

# ============================================================================
# MAIN
# ============================================================================

Write-Section "HMED - Sistema de Analisis de Seguridad con SonarQube"
Write-Log "Script iniciado por: $env:USERNAME" "INFO"
Write-Log "Archivo de log: $LogFile" "INFO"
Write-Log "Directorio: $(Get-Location)" "INFO"

Write-Log "========== PASO 1/5: Verificando Requisitos ===========" "INFO"
if (-not (Test-SystemRequirements)) {
    Write-Log "ERROR: No se cumplen los requisitos minimos" "ERROR"
    Read-Host "Presiona Enter para finalizar"
    exit 1
}

Write-Log "========== PASO 2/5: Verificando Docker ===========" "INFO"
if (-not (Test-Docker)) {
    Write-Log "ERROR: Docker no esta disponible" "ERROR"
    Read-Host "Presiona Enter para finalizar"
    exit 1
}

Write-Log "========== PASO 3/5: Verificando SonarQube ===========" "INFO"
if (-not (Test-SonarQubeConnection)) {
    Write-Log "ERROR: No se puede conectar a SonarQube" "ERROR"
    Read-Host "Presiona Enter para finalizar"
    exit 1
}

Write-Log "========== PASO 4/5: Analizando Estructura ===========" "INFO"
Analyze-CodeStructure

Write-Log "========== PASO 5/5: Ejecutando Analisis ===========" "INFO"
Create-SonarProperties | Out-Null

$success = Run-SonarAnalysisWithDocker

if ($success) {
    Write-Section "ANALISIS COMPLETADO EXITOSAMENTE"
    
    Write-Log "Esperando a SonarQube para procesar resultados..." "INFO"
    Start-Sleep -Seconds 5
    
    Get-SonarQubeMetrics | Out-Null
    
    Write-Log "Abriendo resultados en navegador..." "INFO"
    Try {
        Start-Process "http://localhost:9000/dashboard?id=HMED" -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Log "Abre manualmente: http://localhost:9000/dashboard?id=HMED" "INFO"
    }
    
    Write-Section "INFORMACION DE ACCESO A SONARQUBE"
    Write-Log "Dashboard: http://localhost:9000" "INFO"
    Write-Log "Usuario: admin" "INFO"
    Write-Log "Contrasena: 20394117Tkd+" "INFO"
    Write-Log "Log guardado en: $LogFile" "SUCCESS"
} else {
    Write-Section "ERROR EN EL ANALISIS"
    Write-Log "Verifica:" "WARNING"
    Write-Log "  1. Docker ejecutando: docker ps" "INFO"
    Write-Log "  2. SonarQube en http://localhost:9000" "INFO"
    Write-Log "  3. Red Docker: docker network ls" "INFO"
    Write-Log "  4. Log: $LogFile" "INFO"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " FIN DEL SCRIPT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Add-Content -Path $LogFile -Value "Script ended at: $(Get-Date)" -ErrorAction SilentlyContinue

Read-Host "Presiona Enter para finalizar"
