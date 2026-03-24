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

# ============================================================================
# VARIABLES GLOBALES
# ============================================================================

$SonarToken = $env:SONAR_TOKEN
$SonarPassword = $null
$SonarUser = "admin"

# Inicializar objeto de métricas para tracking de análisis
$AnalysisMetrics = @{
    "Status" = "STARTING"
    "QualityGate" = "UNKNOWN"
    "Duration" = 0
    "ImagePulled" = $false
    "DockerNetwork" = "unknown"
}

# ============================================================================
# FUNCIONES DE UTILIDAD
# ============================================================================

function Read-EnvironmentFile {
    param([string]$FilePath = ".env")
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "Archivo $FilePath no encontrado" "DEBUG"
        return @{}
    }
    
    Write-Log "Leyendo configuracion de $FilePath..." "DEBUG"
    $envVars = @{}
    
    Get-Content $FilePath | ForEach-Object {
        $line = $_.Trim()
        # Ignorar comentarios y líneas vacías
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line -split "=", 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim() -replace '^["\x27]|["\x27]$'
                $envVars[$key] = $value
            }
        }
    }
    
    return $envVars
}

function Get-SonarQubePassword {
    Write-Log "Buscando credenciales de SonarQube..." "INFO"
    
    # 1. Intentar desde variable de entorno DB_PASSWORD
    if ($env:DB_PASSWORD) {
        Write-Log "Contraseña obtenida de variable DB_PASSWORD" "SUCCESS"
        return $env:DB_PASSWORD
    }
    
    # 2. Intentar desde variable SONAR_PASSWORD
    if ($env:SONAR_PASSWORD) {
        Write-Log "Contraseña obtenida de variable SONAR_PASSWORD" "SUCCESS"
        return $env:SONAR_PASSWORD
    }
    
    # 3. Intentar desde archivo .env
    $envVars = Read-EnvironmentFile ".env"
    if ($envVars.ContainsKey("DB_PASSWORD")) {
        Write-Log "Contraseña obtenida de .env (DB_PASSWORD)" "SUCCESS"
        return $envVars["DB_PASSWORD"]
    }
    
    if ($envVars.ContainsKey("SONAR_PASSWORD")) {
        Write-Log "Contraseña obtenida de .env (SONAR_PASSWORD)" "SUCCESS"
        return $envVars["SONAR_PASSWORD"]
    }
    
    Write-Log "No se encontro contraseña en variables de entorno ni en .env" "WARNING"
    return $null
}

function Clear-SonarCache {
    Write-Log "Limpiando cache de SonarScanner..." "INFO"
    
    $cacheDir = ".scannerwork"
    
    if (Test-Path $cacheDir) {
        try {
            Remove-Item -Path $cacheDir -Recurse -Force -ErrorAction Stop
            Write-Log "Carpeta $cacheDir eliminada exitosamente" "SUCCESS"
            return $true
        }
        catch {
            Write-Log "Error al eliminar $cacheDir : $_" "WARNING"
            # No fallar el script por esto, solo advertencia
            return $false
        }
    } else {
        Write-Log "Cache no existe, nada que limpiar" "DEBUG"
        return $true
    }
}

function Start-SonarQubeContainer {
    Write-Log "Intentando iniciar SonarQube con docker-compose..." "INFO"
    
    try {
        Write-Log "Ejecutando: docker-compose --profile sonarqube up -d" "INFO"
        & docker-compose --profile sonarqube up -d 2>&1 | Tee-Object -FilePath $LogFile -Append
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "SonarQube iniciado. Esperando estabilización..." "INFO"
            Start-Sleep -Seconds 15
            return $true
        } else {
            Write-Log "Error iniciando SonarQube" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Excepción al iniciar SonarQube: $_" "ERROR"
        return $false
    }
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
        
        # Construir rutas de cobertura si existen
        $pythonCoverageCmd = ""
        if (Test-Path "backend/coverage.xml") {
            $pythonCoverageCmd = "sonar.python.coverage.reportPath=backend/coverage.xml"
            Write-Log "Coverage Python encontrado: backend/coverage.xml" "DEBUG"
        }
        
        $jsCoverageCmd = ""
        if (Test-Path "frontend/coverage/lcov.info") {
            $jsCoverageCmd = "sonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info"
            Write-Log "Coverage JavaScript encontrado: frontend/coverage/lcov.info" "DEBUG"
        }
        
        $content = @"
sonar.projectKey=HMED
sonar.projectName=HMED - Sistema de Historico Clinico
sonar.projectVersion=1.0
sonar.sourceEncoding=UTF-8
sonar.sources=.
sonar.inclusions=backend/**,frontend/**
sonar.exclusions=**/test*,**/node_modules/**,**/.git/**,**/migrations/**,**/dist/**
sonar.host.url=http://sonarqube:9000
$pythonCoverageCmd
$jsCoverageCmd
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
        # Asegurar que la imagen del scanner existe
        Write-Log "Asegurando imagen del scanner..." "INFO"
        Write-Log "Ejecutando: docker pull sonarsource/sonar-scanner-cli:latest" "DEBUG"
        
        try {
            & docker pull sonarsource/sonar-scanner-cli:latest 2>&1 | Tee-Object -FilePath $LogFile -Append
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Imagen del scanner descargada exitosamente" "SUCCESS"
                $AnalysisMetrics["ImagePulled"] = $true
            } else {
                Write-Log "Advertencia: El pull de la imagen retorno codigo de salida $LASTEXITCODE" "WARNING"
            }
        }
        catch {
            Write-Log "ERROR al descargar imagen del scanner: $_" "ERROR"
            Write-Log "Verifica tu conexion a internet y acceso al registro de Docker" "ERROR"
            Write-Log "Causa posible: Firewall, proxy, o Docker no iniciado" "ERROR"
            $AnalysisMetrics["Status"] = "FAILED_IMAGE_PULL"
            return $false
        }
        
        $token = Get-SonarQubeToken
        $networkName = Get-DockerNetworkName
        $currentDir = Get-Location
        
        $AnalysisMetrics["DockerNetwork"] = $networkName
        
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
            $args += "-Dsonar.login=$SonarUser"
            if ($SonarPassword) {
                $args += "-Dsonar.password=$SonarPassword"
            }
        }
        
        Write-Log "Ejecutando docker scanner..." "INFO"
        
        try {
            & docker $args 2>&1 | Tee-Object -FilePath $LogFile -Append
        }
        catch {
            Write-Log "ERROR al ejecutar docker run: $_" "ERROR"
            Write-Log "Posibles causas:" "ERROR"
            Write-Log "  - Conexion a internet interrumpida" "ERROR"
            Write-Log "  - SonarQube no esta accesible en http://sonarqube:9000" "ERROR"
            Write-Log "  - Red Docker no configurada correctamente" "ERROR"
            Write-Log "Comando ejecutado: docker $($args -join ' ')" "DEBUG"
            $AnalysisMetrics["Status"] = "FAILED_DOCKER_RUN"
            return $false
        }
        
        $AnalysisEndTime = Get-Date
        $Duration = ($AnalysisEndTime - $AnalysisStartTime).TotalSeconds
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Analisis completado exitosamente (${Duration}s)" "SUCCESS"
            $AnalysisMetrics["Status"] = "SUCCESS"
            $AnalysisMetrics["Duration"] = $Duration
            return $true
        } elseif ($LASTEXITCODE -eq 125) {
            Write-Log "Error 125 de Docker: Contenedor no encontrado o error de red" "ERROR"
            Write-Log "Verificando estado de SonarQube..." "WARNING"
            
            if (Start-SonarQubeContainer) {
                Write-Log "SonarQube iniciado exitosamente. Reintentando analisis..." "INFO"
                Write-Log "Por favor ejecuta nuevamente el script: .\install-and-analyze.ps1" "WARNING"
                $AnalysisMetrics["Status"] = "SONARQUBE_STARTED_RETRY_NEEDED"
                return $false
            } else {
                Write-Log "No fue posible iniciar SonarQube automaticamente" "ERROR"
                Write-Log "Diagnóstico: Verifica docker ps, docker logs sonarqube, y conectividad de red" "ERROR"
                $AnalysisMetrics["Status"] = "FAILED_SONARQUBE_ERROR"
                return $false
            }
        } elseif ($LASTEXITCODE -eq 1) {
            Write-Log "Error de análisis (codigo 1): Verificar logs de SonarQube" "ERROR"
            Write-Log "Posibles causas:" "ERROR"
            Write-Log "  - Credenciales incorrectas para SonarQube" "ERROR"
            Write-Log "  - Token expirado o inválido" "ERROR"
            Write-Log "  - Proyecto ya existe con configuracion conflictiva" "ERROR"
            $AnalysisMetrics["Status"] = "FAILED_ANALYSIS_ERROR"
            $AnalysisMetrics["Duration"] = $Duration
            return $false
        } else {
            Write-Log "El analisis termino con codigo $LASTEXITCODE (${Duration}s)" "WARNING"
            Write-Log "Verifica los resultados en http://localhost:9000/dashboard?id=HMED" "INFO"
            $AnalysisMetrics["Status"] = "COMPLETED_WITH_WARNINGS"
            $AnalysisMetrics["Duration"] = $Duration
            return $true
        }
    }
    catch {
        Write-Log "Excepcion al ejecutar analisis: $_" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
        $AnalysisMetrics["Status"] = "FAILED_EXCEPTION"
        $AnalysisMetrics["Duration"] = (Get-Date) - $AnalysisStartTime | Select-Object -ExpandProperty TotalSeconds
        return $false
    }
}

function Get-SonarQubeMetrics {
    Write-Log "Recuperando metricas de SonarQube..." "INFO"
    
    try {
        # Prioridad 1: Usar token de SonarQube si existe
        $headers = @{}
        $authMethod = "desconocida"
        
        if ($env:SONAR_TOKEN) {
            Write-Log "Usando autenticacion con Token de SonarQube" "INFO"
            # En SonarQube, el token se envía como usuario:password siendo usuario=token y password=vacío
            $tokenAuth = "$($env:SONAR_TOKEN):"
            $encodedToken = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($tokenAuth))
            $headers["Authorization"] = "Basic $encodedToken"
            $authMethod = "Token"
        }
        # Prioridad 2: Si no hay token, obtener credenciales del .env
        else {
            Write-Log "Token no encontrado, intenta usando credenciales del .env" "INFO"
            
            # Leer variables del .env si aún no están en memoria
            $envVars = Read-EnvironmentFile ".env"
            
            $sqUser = $null
            $sqPassword = $null
            
            # Intentar obtener SQ_USER
            if ($env:SQ_USER) {
                $sqUser = $env:SQ_USER
            } elseif ($envVars.ContainsKey("SQ_USER")) {
                $sqUser = $envVars["SQ_USER"]
            }
            
            # Intentar obtener SQ_PASSWORD
            if ($env:SQ_PASSWORD) {
                $sqPassword = $env:SQ_PASSWORD
            } elseif ($envVars.ContainsKey("SQ_PASSWORD")) {
                $sqPassword = $envVars["SQ_PASSWORD"]
            }
            
            if (-not $sqUser -or -not $sqPassword) {
                Write-Log "ERROR: No se encontraron credenciales validas" "ERROR"
                Write-Log "  - Variables disponibles: SQ_USER, SQ_PASSWORD, o SONAR_TOKEN" "ERROR"
                $AnalysisMetrics["Status"] = "FAILED_NO_AUTH_CREDENTIALS"
                return $false
            }
            
            Write-Log "Usando autenticacion con credenciales (Usuario: $sqUser)" "INFO"
            $authString = "${sqUser}:${sqPassword}"
            $encodedAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authString))
            $headers["Authorization"] = "Basic $encodedAuth"
            $authMethod = "Credenciales"
        }
        
        Write-Log "Metodo de autenticacion: $authMethod" "DEBUG"
        
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
            $AnalysisMetrics["ProjectKey"] = $project.key
            
            $qgResponse = Invoke-WebRequest `
                -Uri "http://localhost:9000/api/qualitygates/project_status?projectKey=$($project.key)" `
                -Method Get `
                -Headers $headers `
                -UseBasicParsing `
                -ErrorAction Stop
            
            $qg = $qgResponse.Content | ConvertFrom-Json
            $qgStatus = $qg.projectStatus.status
            
            Write-Log "Quality Gate Status: $qgStatus" "SUCCESS"
            $AnalysisMetrics["QualityGate"] = $qgStatus
            $AnalysisMetrics["MetricsRetrieved"] = $true
            return $true
        } else {
            Write-Log "Proyecto HMED no encontrado aun (procesando...)" "WARNING"
            $AnalysisMetrics["Status"] = "PROJECT_NOT_FOUND"
            return $false
        }
    }
    catch [System.Net.WebException] {
        $statusCode = $_.Exception.Response.StatusCode -as [int]
        if ($statusCode -eq 401) {
            Write-Log "ERROR 401 - No Autorizado: Verifica token o credenciales de SonarQube" "ERROR"
            Write-Log "  - Si usas Token: Verifica que SONAR_TOKEN sea valido" "ERROR"
            Write-Log "  - Si usas Credenciales: Verifica SQ_USER y SQ_PASSWORD en .env" "ERROR"
            $AnalysisMetrics["Status"] = "FAILED_UNAUTHORIZED_401"
        }
        elseif ($statusCode -eq 404) {
            Write-Log "ERROR 404 - Servidor SonarQube no encontrado en http://localhost:9000" "ERROR"
            $AnalysisMetrics["Status"] = "FAILED_SONARQUBE_NOT_FOUND"
        }
        else {
            Write-Log "ERROR HTTP ${statusCode}: $_" "ERROR"
            $AnalysisMetrics["Status"] = "FAILED_HTTP_ERROR"
        }
        return $false
    }
    catch {
        Write-Log "Error recuperando metricas: $_" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
        $AnalysisMetrics["Status"] = "FAILED_EXCEPTION"
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

# Obtener credenciales de SonarQube
$SonarPassword = Get-SonarQubePassword
if (-not $SonarPassword) {
    Write-Log "ADVERTENCIA: No se encontraron credenciales de SonarQube" "WARNING"
    Write-Log "El script intentara usar credenciales por defecto o token" "INFO"
}

Write-Log "========== PASO 1/6: Limpiando Cache ===========" "INFO"
Clear-SonarCache | Out-Null

Write-Log "========== PASO 2/6: Verificando Requisitos ===========" "INFO"
if (-not (Test-SystemRequirements)) {
    Write-Log "ERROR: No se cumplen los requisitos minimos" "ERROR"
    Read-Host "Presiona Enter para finalizar"
    exit 1
}

Write-Log "========== PASO 3/6: Verificando Docker ===========" "INFO"
if (-not (Test-Docker)) {
    Write-Log "ERROR: Docker no esta disponible" "ERROR"
    Read-Host "Presiona Enter para finalizar"
    exit 1
}

Write-Log "========== PASO 4/6: Verificando SonarQube ===========" "INFO"
if (-not (Test-SonarQubeConnection)) {
    Write-Log "ERROR: No se puede conectar a SonarQube" "ERROR"
    Read-Host "Presiona Enter para finalizar"
    exit 1
}

Write-Log "========== PASO 5/6: Analizando Estructura ===========" "INFO"
Analyze-CodeStructure

Write-Log "========== PASO 6/6: Ejecutando Analisis ===========" "INFO"
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
    Write-Log "Usuario: $SonarUser" "INFO"
    if ($SonarPassword) {
        Write-Log "Contrasena: $($SonarPassword.Substring(0, [Math]::Min(3, $SonarPassword.Length)))..." "INFO"
    }
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
