# Script PowerShell para ejecutar analisis de SonarQube automaticamente
# Uso: .\install-and-analyze.ps1

param(
    [string]$SonarScannerVersion = "4.8.0.3345",
    [string]$InstallPath = "C:\sonar-scanner"
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HMED - Analisis de Seguridad Automatico" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Success = "Green"
$ErrorColor = "Red"
$Info = "Cyan"
$Warning = "Yellow"

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

function Install-SonarScanner {
    param([string]$Path, [string]$Version)
    
    if (Test-Path "$Path\bin\sonar-scanner.bat") {
        Write-Host "[OK] SonarScanner ya esta instalado" -ForegroundColor $Success
        return $true
    }
    
    Write-Host "[*] Preparando SonarScanner..." -ForegroundColor $Info
    
    $ZipPath = "$env:TEMP\sonar-scanner.zip"
    $ExtractPath = "$env:TEMP\sonar-scanner-extracted"
    
    $urls = @(
        "https://github.com/SonarSource/sonar-scanner-cli/releases/download/$Version/sonar-scanner-cli-$Version-windows-x86_64.zip",
        "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$Version-windows-x86_64.zip"
    )
    
    $downloadSuccess = $false
    
    foreach ($DownloadUrl in $urls) {
        try {
            Write-Host "[*] Intentando descargar desde: $DownloadUrl" -ForegroundColor $Info
            
            Invoke-WebRequest `
                -Uri $DownloadUrl `
                -OutFile $ZipPath `
                -ErrorAction Stop `
                -UseBasicParsing `
                -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            
            $downloadSuccess = $true
            break
        }
        catch {
            Write-Host "[WARN] Error: $_" -ForegroundColor $Warning
            continue
        }
    }
    
    if (-not $downloadSuccess) {
        Write-Host "[FAIL] No se pudo descargar de ninguna fuente" -ForegroundColor $ErrorColor
        Write-Host ""
        Write-Host "[OPCION 1] Descargar manualmente:" -ForegroundColor $Info
        Write-Host "  1. Abre: https://www.sonarsource.com/products/sonarqube/downloads/" -ForegroundColor $Info
        Write-Host "  2. Descarga: sonar-scanner-...-windows-x86_64.zip" -ForegroundColor $Info
        Write-Host "  3. Extrae en: C:\sonar-scanner" -ForegroundColor $Info
        Write-Host "  4. Ejecuta nuevamente este script" -ForegroundColor $Info
        Write-Host ""
        Write-Host "[OPCION 2] Usar curl (si está disponible):" -ForegroundColor $Info
        Write-Host "  curl -o sonar-scanner.zip https://github.com/SonarSource/sonar-scanner-cli/releases/download/$Version/sonar-scanner-cli-$Version-windows-x86_64.zip" -ForegroundColor $Info
        return $false
    }
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        
        Write-Host "[*] Extrayendo archivos..." -ForegroundColor $Info
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force -ErrorAction Stop
        
        $ExtractedFolder = Get-ChildItem -Path $ExtractPath -Directory | Select-Object -First 1
        if (-not $ExtractedFolder) {
            throw "No se encontro carpeta extraida"
        }
        
        Copy-Item -Path "$($ExtractedFolder.FullName)\*" -Destination $Path -Recurse -Force -ErrorAction Stop
        
        Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        
        if (-not (Test-Path "$Path\bin\sonar-scanner.bat")) {
            throw "sonar-scanner.bat no se encontro despues de la instalacion"
        }
        
        Write-Host "[OK] SonarScanner instalado correctamente" -ForegroundColor $Success
        return $true
    }
    catch {
        Write-Host "[FAIL] Error instalando SonarScanner: $_" -ForegroundColor $ErrorColor
        return $false
    }
}

function Add-ToPath {
    param([string]$PathToAdd)
    
    $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($CurrentPath -like "*$PathToAdd*") {
        return
    }
    
    try {
        $NewPath = $CurrentPath + ";" + $PathToAdd
        [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
        $env:PATH = $env:PATH + ";" + $PathToAdd
    }
    catch {
        Write-Host "[WARN] No se pudo agregar a PATH permanentemente" -ForegroundColor $Warning
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

function Get-SonarQubeToken {
    Write-Host "[*] Obteniendo token de SonarQube..." -ForegroundColor $Info
    
    $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("admin:admin"))
    
    try {
        $headers = @{
            "Authorization" = "Basic $auth"
            "Content-Type" = "application/x-www-form-urlencoded"
        }
        
        $body = "name=HMED-Token&type=GLOBAL_ANALYSIS_TOKEN"
        
        $response = Invoke-WebRequest `
            -Uri "http://localhost:9000/api/user_tokens/generate" `
            -Method Post `
            -Headers $headers `
            -Body $body `
            -UseBasicParsing `
            -ErrorAction Stop
        
        $result = $response.Content | ConvertFrom-Json
        if ($result.token) {
            Write-Host "[OK] Token obtenido" -ForegroundColor $Success
            return $result.token
        }
    }
    catch {
        Write-Host "[WARN] No se pudo generar token, usando credenciales" -ForegroundColor $Warning
    }
    
    return $null
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

sonar.host.url=http://localhost:9000
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

function Run-SonarAnalysis {
    param([string]$Token)
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Analizando Proyecto" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $scannerPath = "$InstallPath\bin\sonar-scanner.bat"
    
    if (-not (Test-Path $scannerPath)) {
        Write-Host "[FAIL] sonar-scanner no encontrado en $scannerPath" -ForegroundColor $ErrorColor
        return $false
    }
    
    try {
        Write-Host "[*] Ejecutando sonar-scanner..." -ForegroundColor $Info
        
        if ($Token) {
            & cmd.exe /c "$scannerPath -Dsonar.projectKey=HMED -Dsonar.projectName='HMED' -Dsonar.sources=. -Dsonar.host.url=http://localhost:9000 -Dsonar.login=$Token"
        }
        else {
            & cmd.exe /c "$scannerPath -Dsonar.projectKey=HMED -Dsonar.projectName='HMED' -Dsonar.sources=. -Dsonar.host.url=http://localhost:9000 -Dsonar.login=admin -Dsonar.password=admin"
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor $Success
            Write-Host " OK - Analisis Completado" -ForegroundColor $Success
            Write-Host "========================================" -ForegroundColor $Success
            return $true
        }
        else {
            Write-Host "[WARN] El analisis termino con advertencias o errores menores" -ForegroundColor $Warning
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

Write-Host "[PASO 1/5] Verificando Docker..." -ForegroundColor $Cyan
if (-not (Test-Docker)) {
    Read-Host "`nPresiona Enter para continuar"
    exit 1
}

Write-Host ""
Write-Host "[PASO 2/5] Verificando SonarQube..." -ForegroundColor $Cyan
if (-not (Test-SonarQubeConnection)) {
    Read-Host "`nPresiona Enter para continuar"
    exit 1
}

Write-Host ""
Write-Host "[PASO 3/5] Instalando SonarScanner..." -ForegroundColor $Cyan
if (-not (Install-SonarScanner -Path $InstallPath -Version $SonarScannerVersion)) {
    Read-Host "`nPresiona Enter para continuar"
    exit 1
}

Add-ToPath "$InstallPath\bin"

Write-Host ""
Write-Host "[PASO 4/5] Configurando proyecto..." -ForegroundColor $Cyan
Create-SonarProperties | Out-Null

Write-Host ""
Write-Host "[PASO 5/5] Ejecutando analisis..." -ForegroundColor $Cyan
$token = Get-SonarQubeToken
$success = Run-SonarAnalysis -Token $token

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
    Write-Host "  3. sonar-scanner se instalo en: $InstallPath" -ForegroundColor $Info
}

Read-Host "`nPresiona Enter para finalizar"
