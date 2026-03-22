# Script mejorado para descargar reportes de SonarQube via API
# Uso: .\export-sonar-report.ps1

$ErrorActionPreference = "Continue"
$ScriptStartTime = Get-Date
$LogsDirectory = "logs"
$ReportDir = "sonar-reports"

# Crear directorios
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}

$SonarUrl = "http://localhost:9000"
$SonarToken = "sqa_b0fc01f42ecb4a96c12c471ca38c00f00e48d892"
$ProjectKey = "HMED"

# ============================================================================
# FUNCIONES DE LOGGING
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
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
# FUNCIONES DE DESCARGA CON REINTENTOS
# ============================================================================

function Invoke-SonarWebRequest {
    param(
        [string]$Uri,
        [int]$MaxRetries = 3
    )
    
    $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("admin:20394117Tkd+"))
    $headers = @{
        "Authorization" = "Basic $auth"
        "Content-Type" = "application/json"
    }
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest `
                -Uri $Uri `
                -Headers $headers `
                -UseBasicParsing `
                -TimeoutSec 30 `
                -ErrorAction Stop
            return $response
        }
        catch {
            if ($i -lt $MaxRetries) {
                Write-Log "Reintentando en 2 segundos ($i/$MaxRetries)..." "WARNING"
                Start-Sleep -Seconds 2
            } else {
                Write-Log "Error despues de $MaxRetries intentos: $_" "ERROR"
                throw $_
            }
        }
    }
}

# ============================================================================
# FUNCIONES DE EXPORTACION
# ============================================================================

function Export-IssuesData {
    Write-Log "Descargando Issues (Bugs, Vulnerabilidades, Code Smells)..." "INFO"
    
    $allIssues = @()
    $pageSize = 500
    $page = 1
    $totalFetched = 0
    
    do {
        try {
            $issuesUrl = "$SonarUrl/api/issues/search?componentKeys=$ProjectKey&ps=$pageSize&p=$page&types=BUG,VULNERABILITY,CODE_SMELL"
            $response = Invoke-SonarWebRequest -Uri $issuesUrl
            $data = $response.Content | ConvertFrom-Json
            
            if ($data.issues.Count -eq 0) { break }
            
            $allIssues += $data.issues
            $totalFetched += $data.issues.Count
            
            Write-Log "Pagina $page`: $($data.issues.Count) issues (Total: $totalFetched/$($data.total))" "DEBUG"
            $page++
        }
        catch {
            Write-Log "Error descargando issues pagina $page" "ERROR"
            break
        }
    } while ($totalFetched -lt $data.total)
    
    if ($allIssues.Count -gt 0) {
        # Guardar JSON
        $allIssues | ConvertTo-Json -Depth 10 | Out-File "$ReportDir/issues.json" -Encoding UTF8
        Write-Log "Issues guardados: $($allIssues.Count) total" "SUCCESS"
        
        # Guardar CSV
        $csvData = @()
        foreach ($issue in $allIssues) {
            $csvData += [PSCustomObject]@{
                key = $issue.key
                type = $issue.type
                severity = $issue.severity
                status = $issue.status
                message = $issue.message
                component = $issue.component
                line = $issue.line
                effort = $issue.effort
            }
        }
        $csvData | Export-Csv "$ReportDir/issues.csv" -NoTypeInformation -Encoding UTF8
        Write-Log "CSV generado: issues.csv" "SUCCESS"
    }
    
    return $allIssues.Count
}

function Export-MetricsData {
    Write-Log "Descargando Metricas del Proyecto..." "INFO"
    
    try {
        $metricsUrl = "$SonarUrl/api/measures/component?component=$ProjectKey&metricKeys=lines,ncloc,complexity,sqale_index,bugs,vulnerabilities,code_smells,security_hotspots,coverage,duplicated_lines_density"
        $response = Invoke-SonarWebRequest -Uri $metricsUrl
        $data = $response.Content | ConvertFrom-Json
        
        # Guardar JSON
        $data | ConvertTo-Json -Depth 10 | Out-File "$ReportDir/metrics.json" -Encoding UTF8
        
        # Crear CSV con metricas formateadas
        $csvMetrics = @()
        foreach ($measure in $data.component.measures) {
            $csvMetrics += [PSCustomObject]@{
                Metrica = $measure.metric
                Valor = $measure.value
                Periodo = if ($measure.period) { $measure.period.date } else { "N/A" }
            }
        }
        $csvMetrics | Export-Csv "$ReportDir/metrics.csv" -NoTypeInformation -Encoding UTF8
        
        Write-Log "Metricas guardadas: $($csvMetrics.Count) metricas" "SUCCESS"
        return $csvMetrics.Count
    }
    catch {
        Write-Log "Error descargando metricas: $_" "ERROR"
        return 0
    }
}

function Export-SecurityHotspots {
    Write-Log "Descargando Security Hotspots..." "INFO"
    
    $allHotspots = @()
    
    try {
        $hotspotsUrl = "$SonarUrl/api/hotspots/search?projectKey=$ProjectKey&ps=500"
        $response = Invoke-SonarWebRequest -Uri $hotspotsUrl
        $data = $response.Content | ConvertFrom-Json
        
        if ($data.hotspots) {
            $allHotspots = $data.hotspots
            
            # Guardar JSON
            $allHotspots | ConvertTo-Json -Depth 10 | Out-File "$ReportDir/hotspots.json" -Encoding UTF8
            
            # Guardar CSV
            $csvHotspots = @()
            foreach ($hotspot in $allHotspots) {
                $csvHotspots += [PSCustomObject]@{
                    key = $hotspot.key
                    component = $hotspot.component
                    vulnerabilityProbability = $hotspot.vulnerabilityProbability
                    status = $hotspot.status
                    line = $hotspot.line
                    message = $hotspot.message
                }
            }
            $csvHotspots | Export-Csv "$ReportDir/hotspots.csv" -NoTypeInformation -Encoding UTF8
            
            Write-Log "Hotspots guardados: $($allHotspots.Count) total" "SUCCESS"
        }
    }
    catch {
        Write-Log "Error descargando hotspots: $_" "ERROR"
    }
    
    return $allHotspots.Count
}

function Export-ProjectInfo {
    Write-Log "Descargando Informacion del Proyecto..." "INFO"
    
    try {
        $projectUrl = "$SonarUrl/api/components/show?component=$ProjectKey"
        $response = Invoke-SonarWebRequest -Uri $projectUrl
        $data = $response.Content | ConvertFrom-Json
        
        # Guardar JSON
        $data | ConvertTo-Json -Depth 10 | Out-File "$ReportDir/project-info.json" -Encoding UTF8
        
        Write-Log "Informacion del proyecto guardada" "SUCCESS"
        return $data.component
    }
    catch {
        Write-Log "Error descargando info del proyecto: $_" "ERROR"
        return $null
    }
}

function Export-QualityGate {
    Write-Log "Descargando Quality Gate Status..." "INFO"
    
    try {
        $qgUrl = "$SonarUrl/api/qualitygates/project_status?projectKey=$ProjectKey"
        $response = Invoke-SonarWebRequest -Uri $qgUrl
        $data = $response.Content | ConvertFrom-Json
        
        # Guardar JSON
        $data | ConvertTo-Json -Depth 10 | Out-File "$ReportDir/quality-gate.json" -Encoding UTF8
        
        Write-Log "Quality Gate Status: $($data.projectStatus.status)" "INFO"
        return $data.projectStatus
    }
    catch {
        Write-Log "Error descargando Quality Gate: $_" "ERROR"
        return $null
    }
}

function Export-DuplicatedLines {
    Write-Log "Descargando Duplicacion de Codigo..." "INFO"
    
    try {
        $dupUrl = "$SonarUrl/api/measures/search_history?component=$ProjectKey&metrics=duplicated_lines,duplicated_blocks"
        $response = Invoke-SonarWebRequest -Uri $dupUrl
        $data = $response.Content | ConvertFrom-Json
        
        $data | ConvertTo-Json -Depth 10 | Out-File "$ReportDir/duplicated-lines.json" -Encoding UTF8
        
        Write-Log "Duplicacion descargada" "SUCCESS"
        return 1
    }
    catch {
        Write-Log "Error descargando duplicacion: $_" "ERROR"
        return 0
    }
}

# ============================================================================
# FUNCIONES DE REPORTE
# ============================================================================

function Generate-HTMLReport {
    param(
        [object]$Stats
    )
    
    Write-Log "Generando reporte HTML..." "INFO"
    
    $htmlFile = "$ReportDir/report.html"
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Reporte SonarQube - $ProjectKey</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .section { background: white; margin: 20px 0; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #34495e; color: white; }
        .success { color: #27ae60; font-weight: bold; }
        .error { color: #e74c3c; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
        .metric-box { display: inline-block; background: #ecf0f1; padding: 15px; margin: 10px; border-radius: 5px; min-width: 200px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #2c3e50; }
        .metric-label { font-size: 12px; color: #7f8c8d; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Reporte de Analisis - SonarQube</h1>
        <p>Proyecto: <strong>$ProjectKey</strong></p>
        <p>Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
    </div>
    
    <div class="section">
        <h2>Resumen de Hallazgos</h2>
        <div class="metric-box">
            <div class="metric-label">Issues Totales</div>
            <div class="metric-value">$($Stats.TotalIssues)</div>
        </div>
        <div class="metric-box">
            <div class="metric-label">Hotspots de Seguridad</div>
            <div class="metric-value">$($Stats.TotalHotspots)</div>
        </div>
        <div class="metric-box">
            <div class="metric-label">Metricas</div>
            <div class="metric-value">$($Stats.TotalMetrics)</div>
        </div>
    </div>
    
    <div class="section">
        <h2>Archivos Descargados</h2>
        <table>
            <tr>
                <th>Archivo</th>
                <th>Tamano</th>
                <th>Formato</th>
            </tr>
"@
    
    Get-ChildItem -Path $ReportDir -File | ForEach-Object {
        $size = [Math]::Round($_.Length / 1024, 2)
        $html += "<tr><td>$($_.Name)</td><td>$size KB</td><td>$($_.Extension)</td></tr>`n"
    }
    
    $html += @"
        </table>
    </div>
    
    <div class="section">
        <h2>Proximos Pasos</h2>
        <ul>
            <li>Revisar issues.csv para detalles de cada hallazgo</li>
            <li>Analizar metrics.csv para tendencias</li>
            <li>Revisar security hotspots en hotspots.csv</li>
            <li>Consultar SonarQube: <a href="$SonarUrl">$SonarUrl</a></li>
        </ul>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $htmlFile -Encoding UTF8
    Write-Log "Reporte HTML generado: report.html" "SUCCESS"
}

# ============================================================================
# MAIN
# ============================================================================

Write-Section "DESCARGA DE REPORTES DESDE SONARQUBE"
Write-Log "Iniciando descarga de datos para: $ProjectKey" "INFO"
Write-Log "URL SonarQube: $SonarUrl" "INFO"

# Inicializadores estadisticas
$stats = @{
    TotalIssues = 0
    TotalHotspots = 0
    TotalMetrics = 0
    StartTime = Get-Date
}

# Ejecutar descargas
Write-Host ""
$stats.TotalIssues = Export-IssuesData
Write-Host ""
$stats.TotalMetrics = Export-MetricsData
Write-Host ""
$stats.TotalHotspots = Export-SecurityHotspots
Write-Host ""
Export-ProjectInfo | Out-Null
Write-Host ""
Export-QualityGate | Out-Null
Write-Host ""
Export-DuplicatedLines | Out-Null

# Generar reportes
Write-Host ""
Generate-HTMLReport -Stats $stats

# Mostrar resumen final
Write-Section "DESCARGA COMPLETADA"
$duration = ((Get-Date) - $stats.StartTime).TotalSeconds

Write-Log "Directorio de reportes: $(Resolve-Path $ReportDir)" "INFO"
Write-Log "Duracion total: $duration segundos" "INFO"
Write-Log "Estadisticas:" "INFO"
Write-Log "  - Issues descargados: $($stats.TotalIssues)" "SUCCESS"
Write-Log "  - Hotspots descargados: $($stats.TotalHotspots)" "SUCCESS"
Write-Log "  - Metricas descargadas: $($stats.TotalMetrics)" "SUCCESS"

Write-Host ""
Write-Log "Archivos generados:" "INFO"
Get-ChildItem -Path $ReportDir -File | ForEach-Object {
    $size = [Math]::Round($_.Length / 1024, 2)
    Write-Log "  $($_.Name) ($size KB)" "SUCCESS"
}

Write-Host ""
Write-Log "Abriendo reporte HTML..." "INFO"
Start-Process "$ReportDir/report.html" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " OPERACION COMPLETADA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Read-Host "Presiona Enter para finalizar"

