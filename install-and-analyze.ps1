# Script PowerShell para instalar Sonar Scanner y ejecutar análisis de SonarQube
# Uso: .\install-and-analyze.ps1

param(
    [string]$SonarScannerVersion = "4.8.0.3345",
    [string]$InstallPath = "C:\sonar-scanner"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HMED - Instalacion de SonarQube" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Colores para output
$Success = "Green"
$Error = "Red"
$Info = "Cyan"
$Warning = "Yellow"

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

function Test-Java {
    try {
        $output = & java -version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[✓] Java detectado" -ForegroundColor $Success
            return $true
        }
    }
    catch { }
    
    Write-Host "[ERROR] Java no está instalado" -ForegroundColor $Error
    Write-Host "Descargar desde: https://www.oracle.com/java/technologies/downloads/" -ForegroundColor $Warning
    return $false
}

function Install-SonarScanner {
    param([string]$Path, [string]$Version)
    
    if (Test-Path "$Path\bin\sonar-scanner.bat") {
        Write-Host "[✓] SonarScanner ya está instalado en $Path" -ForegroundColor $Success
        return $true
    }
    
    Write-Host "[*] Descargando SonarScanner $Version..." -ForegroundColor $Info
    
    $DownloadUrl = "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$Version-windows-x86_64.zip"
    $ZipPath = "$env:TEMP\sonar-scanner.zip"
    $ExtractPath = "$env:TEMP\sonar-scanner-extracted"
    
    try {
        # Crear directorio si no existe
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        
        # Descargar
        Write-Host "[*] Descargando desde: $DownloadUrl" -ForegroundColor $Info
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -ErrorAction Stop
        
        # Extraer
        Write-Host "[*] Extrayendo archivos..." -ForegroundColor $Info
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
        
        # Copiar a destino final
        $ExtractedFolder = Get-ChildItem -Path $ExtractPath -Directory | Select-Object -First 1
        Copy-Item -Path "$($ExtractedFolder.FullName)\*" -Destination $Path -Recurse -Force
        
        # Limpiar temporales
        Remove-Item $ZipPath -Force
        Remove-Item $ExtractPath -Recurse -Force
        
        Write-Host "[✓] SonarScanner instalado en $Path" -ForegroundColor $Success
        return $true
    }
    catch {
        Write-Host "[ERROR] Fallo al descargar SonarScanner: $_" -ForegroundColor $Error
        return $false
    }
}

function Add-ToPath {
    param([string]$Path)
    
    $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($CurrentPath -contains $Path) {
        Write-Host "[✓] $Path ya está en PATH" -ForegroundColor $Success
        return
    }
    
    try {
        [Environment]::SetEnvironmentVariable(
            "PATH",
            "$CurrentPath;$Path",
            "User"
        )
        Write-Host "[✓] Agregado $Path a PATH" -ForegroundColor $Success
        $env:PATH = "$env:PATH;$Path"
    }
    catch {
        Write-Host "[ERROR] No se pudo agregar a PATH: $_" -ForegroundColor $Error
    }
}

function Test-SonarQubeConnection {
    Write-Host "[*] Verificando conexión a SonarQube..." -ForegroundColor $Info
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9000/api/system/health" -ErrorAction Stop
        Write-Host "[✓] SonarQube está activo" -ForegroundColor $Success
        return $true
    }
    catch {
        Write-Host "[ERROR] No se puede conectar a SonarQube en http://localhost:9000" -ForegroundColor $Error
        Write-Host "Inicia SonarQube con: docker-compose up -d sonarqube db" -ForegroundColor $Warning
        return $false
    }
}

function Run-SonarAnalysis {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Iniciando análisis de seguridad..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    & sonar-scanner `
        -Dsonar.projectBaseDir=. `
        -Dsonar.host.url=http://localhost:9000 `
        -Dsonar.login=admin `
        -Dsonar.password=admin
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor $Success
        Write-Host " ✓ Análisis completado exitosamente" -ForegroundColor $Success
        Write-Host "========================================" -ForegroundColor $Success
        Write-Host ""
        Write-Host "Resultados disponibles en:" -ForegroundColor $Info
        Write-Host "  http://localhost:9000/projects" -ForegroundColor $Success
        Write-Host ""
        return $true
    }
    else {
        Write-Host "[ERROR] El análisis falló" -ForegroundColor $Error
        return $false
    }
}

# ============================================================================
# MAIN
# ============================================================================

# 1. Verificar Java
Write-Host "[*] Verificando dependencias..." -ForegroundColor $Info
if (-not (Test-Java)) {
    Read-Host "Presiona Enter para continuar..."
    exit 1
}

# 2. Instalar SonarScanner
Write-Host "[*] Verificando SonarScanner..." -ForegroundColor $Info
if (-not (Install-SonarScanner -Path $InstallPath -Version $SonarScannerVersion)) {
    Read-Host "Presiona Enter para continuar..."
    exit 1
}

# 3. Agregar a PATH
Add-ToPath "$InstallPath\bin"

# 4. Verificar SonarQube
if (-not (Test-SonarQubeConnection)) {
    Read-Host "Presiona Enter para continuar..."
    exit 1
}

# 5. Ejecutar análisis
if (Run-SonarAnalysis) {
    Read-Host "Presiona Enter para abrir resultados en navegador..."
    Start-Process "http://localhost:9000/projects"
}
else {
    Read-Host "Presiona Enter para continuar..."
    exit 1
}
