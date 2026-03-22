# Script para descargar reporte de SonarQube via API

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Green
Write-Host " Descargando Reporte de SonarQube"
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Configuración
$SonarUrl = "http://localhost:9000"
$SonarToken = "sqa_b0fc01f42ecb4a96c12c471ca38c00f00e48d892"
$ProjectKey = "HMED"
$OutputDir = "./sonar-reports"

# Crear directorio de salida
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "[OK] Directorio creado: $OutputDir" -ForegroundColor Green
}

# Headers para autenticación
$headers = @{
    "Authorization" = "Bearer $SonarToken"
    "Content-Type" = "application/json"
}

Write-Host ""
Write-Host "[*] Descargando datos del proyecto: $ProjectKey" -ForegroundColor Cyan
Write-Host ""

# 1. Descargar Issues (Bugs, Vulnerabilidades, Code Smells)
Write-Host "[1/4] Descargando Issues..." -ForegroundColor Cyan
try {
    $issuesUrl = "$SonarUrl/api/issues/search?componentKeys=$ProjectKey&ps=500&types=BUG,VULNERABILITY,CODE_SMELL"
    $issuesResponse = Invoke-WebRequest `
        -Uri $issuesUrl `
        -Headers $headers `
        -UseBasicParsing
    
    $issuesFile = "$OutputDir/sonar-issues.json"
    $issuesResponse.Content | Out-File -FilePath $issuesFile -Encoding UTF8
    
    $issuesCount = ($issuesResponse.Content | ConvertFrom-Json).total
    Write-Host "[OK] $issuesCount issues descargados" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Error descargando issues: $_" -ForegroundColor Red
}

# 2. Descargar Métricas del Proyecto
Write-Host "[2/4] Descargando métricas..." -ForegroundColor Cyan
try {
    $metricsUrl = "$SonarUrl/api/measures/search_history?component=$ProjectKey&metrics=lines,coverage,sqale_index,bugs,vulnerabilities,code_smells,security_hotspots"
    $metricsResponse = Invoke-WebRequest `
        -Uri $metricsUrl `
        -Headers $headers `
        -UseBasicParsing
    
    $metricsFile = "$OutputDir/sonar-metrics.json"
    $metricsResponse.Content | Out-File -FilePath $metricsFile -Encoding UTF8
    Write-Host "[OK] Métricas descargadas" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Error descargando métricas: $_" -ForegroundColor Red
}

# 3. Descargar Puntos de Acceso de Seguridad
Write-Host "[3/4] Descargando security hotspots..." -ForegroundColor Cyan
try {
    $hotspotsUrl = "$SonarUrl/api/hotspots/search?projectKey=$ProjectKey&ps=500"
    $hotspotsResponse = Invoke-WebRequest `
        -Uri $hotspotsUrl `
        -Headers $headers `
        -UseBasicParsing
    
    $hotspotsFile = "$OutputDir/sonar-hotspots.json"
    $hotspotsResponse.Content | Out-File -FilePath $hotspotsFile -Encoding UTF8
    
    $hotspotsCount = ($hotspotsResponse.Content | ConvertFrom-Json).hotspots.Count
    Write-Host "[OK] $hotspotsCount security hotspots descargados" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Error descargando hotspots: $_" -ForegroundColor Red
}

# 4. Descargar Información General del Proyecto
Write-Host "[4/4] Descargando información del proyecto..." -ForegroundColor Cyan
try {
    $projectUrl = "$SonarUrl/api/components/show?component=$ProjectKey"
    $projectResponse = Invoke-WebRequest `
        -Uri $projectUrl `
        -Headers $headers `
        -UseBasicParsing
    
    $projectFile = "$OutputDir/sonar-project.json"
    $projectResponse.Content | Out-File -FilePath $projectFile -Encoding UTF8
    Write-Host "[OK] Información del proyecto descargada" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Error descargando información: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Descargas Completadas"
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Archivos descargados en: $OutputDir" -ForegroundColor Cyan
Write-Host ""

# Listar archivos descargados
Get-ChildItem -Path $OutputDir -Filter "*.json" | ForEach-Object {
    $size = (Get-Item $_.FullName).Length
    Write-Host "  ✓ $($_.Name) - $('{0:N0}' -f $size) bytes" -ForegroundColor Green
}

Write-Host ""
Write-Host "Para revisar los datos:" -ForegroundColor Cyan
Write-Host "  - Abre: $OutputDir\sonar-issues.json" -ForegroundColor Yellow
Write-Host "  - O ejecuta: notepad .\sonar-reports\sonar-issues.json" -ForegroundColor Yellow
Write-Host ""

Read-Host "Presiona Enter para finalizar"
