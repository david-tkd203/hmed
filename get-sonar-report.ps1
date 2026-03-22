Write-Host "========================================" -ForegroundColor Green
Write-Host " Descargando Reporte de SonarQube" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$SonarUrl = "http://localhost:9000"
$SonarToken = "sqa_b0fc01f42ecb4a96c12c471ca38c00f00e48d892"
$ProjectKey = "HMED"
$OutputDir = "./sonar-reports"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "[OK] Directorio creado: $OutputDir" -ForegroundColor Green
}

$headers = @{
    "Authorization" = "Bearer $SonarToken"
}

Write-Host ""
Write-Host "[1/4] Descargando Issues..." -ForegroundColor Cyan

try {
    $issuesUrl = "$SonarUrl/api/issues/search?componentKeys=$ProjectKey&ps=500&types=BUG,VULNERABILITY,CODE_SMELL"
    $issuesResponse = Invoke-WebRequest -Uri $issuesUrl -Headers $headers -UseBasicParsing
    $issuesFile = "$OutputDir/sonar-issues.json"
    $issuesResponse.Content | Out-File -FilePath $issuesFile -Encoding UTF8
    
    $issuesData = $issuesResponse.Content | ConvertFrom-Json
    Write-Host "[OK] $($issuesData.total) issues descargados" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Error: $_" -ForegroundColor Red
}

Write-Host "[2/4] Descargando Metricas..." -ForegroundColor Cyan

try {
    $metricsUrl = "$SonarUrl/api/measures/component?component=$ProjectKey&metricKeys=lines,coverage,sqale_index,bugs,vulnerabilities,code_smells,security_hotspots"
    $metricsResponse = Invoke-WebRequest -Uri $metricsUrl -Headers $headers -UseBasicParsing
    $metricsFile = "$OutputDir/sonar-metrics.json"
    $metricsResponse.Content | Out-File -FilePath $metricsFile -Encoding UTF8
    Write-Host "[OK] Metricas descargadas" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Error: $_" -ForegroundColor Red
}

Write-Host "[3/4] Descargando Security Hotspots..." -ForegroundColor Cyan

try {
    $hotspotsUrl = "$SonarUrl/api/hotspots/search?projectKey=$ProjectKey&ps=500"
    $hotspotsResponse = Invoke-WebRequest -Uri $hotspotsUrl -Headers $headers -UseBasicParsing
    $hotspotsFile = "$OutputDir/sonar-hotspots.json"
    $hotspotsResponse.Content | Out-File -FilePath $hotspotsFile -Encoding UTF8
    
    $hotspotsData = $hotspotsResponse.Content | ConvertFrom-Json
    Write-Host "[OK] $($hotspotsData.hotspots.Count) hotspots descargados" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Error: $_" -ForegroundColor Red
}

Write-Host "[4/4] Descargando Informacion del Proyecto..." -ForegroundColor Cyan

try {
    $projectUrl = "$SonarUrl/api/components/show?component=$ProjectKey"
    $projectResponse = Invoke-WebRequest -Uri $projectUrl -Headers $headers -UseBasicParsing
    $projectFile = "$OutputDir/sonar-project.json"
    $projectResponse.Content | Out-File -FilePath $projectFile -Encoding UTF8
    Write-Host "[OK] Informacion del proyecto descargada" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Descarga Completada" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Archivos generados en: $OutputDir" -ForegroundColor Cyan
Write-Host ""

$files = Get-ChildItem -Path $OutputDir -Filter "*.json"
foreach ($file in $files) {
    $size = $file.Length
    Write-Host "  * $($file.Name) ($size bytes)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Puedes revisar los archivos con:" -ForegroundColor Cyan
Write-Host "  notepad .\sonar-reports\sonar-issues.json" -ForegroundColor Yellow
Write-Host ""
