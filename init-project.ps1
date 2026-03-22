#!/usr/bin/env powershell

# Script de inicialización para Historico Clinico en Windows
# Uso: .\init-project.ps1

param(
    [switch]$Clean,
    [switch]$SkipBuilding
)

# Función para imprimir con colores
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host $Text.PadRight(60).Substring(0, 60) -ForegroundColor Magenta
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-Host "▶ $Text" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "✅ $Text" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "❌ $Text" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Text)
    Write-Host "⚠️  $Text" -ForegroundColor Yellow
}

# Inicio
Clear-Host
Write-Header "INICIALIZADOR DE HISTORICO CLINICO"

Write-Host "Fecha/Hora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "Directorio: $(Get-Location)" -ForegroundColor White
Write-Host ""

# PASO 1: Verificaciones previas
Write-Header "PASO 1: VERIFICACIONES PREVIAS"

Write-Step "Verificando Docker..."
try {
    $dockerVersion = docker --version
    Write-Success "Docker encontrado: $dockerVersion"
} catch {
    Write-Error-Custom "Docker no está instalado o no es accesible"
    exit 1
}

Write-Step "Verificando archivo .env..."
if (Test-Path ".env") {
    Write-Success "Archivo .env encontrado"
} else {
    Write-Warning-Custom "Archivo .env no encontrado. Se usarán valores por defecto."
}

# PASO 2: Limpiar (opcional)
Write-Header "PASO 2: LIMPIEZA PREVIA"

if ($Clean) {
    Write-Step "Deteniendo y eliminando contenedores previos..."
    docker-compose down -v --remove-orphans
    Write-Success "Limpieza completada"
} else {
    Write-Warning-Custom "Los contenedores previos se mantienen. Use -Clean para limpiar."
}

# PASO 3: Compilar imágenes
if (-not $SkipBuilding) {
    Write-Header "PASO 3: COMPILACIÓN DE IMÁGENES DOCKER"
    
    Write-Step "Compilando imágenes..."
    Write-Host "  Esto puede tomar varios minutos en la primera ejecución...`n"
    
    docker-compose build
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Error al compilar imágenes Docker"
        exit 1
    }
    
    Write-Success "Imágenes compiladas correctamente"
} else {
    Write-Warning-Custom "Se omite la compilación de imágenes (-SkipBuilding)"
}

# PASO 4: Iniciar servicios
Write-Header "PASO 4: INICIAR SERVICIOS"

Write-Step "Iniciando servicios Docker..."
Write-Host "  Esperando a que los servicios estén listos...`n"

docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Error al iniciar servicios"
    exit 1
}

Write-Success "Servicios iniciados"

# PASO 5: Esperar a que la BD esté lista
Write-Header "PASO 5: ESPERAR A QUE LA BASE DE DATOS ESTÉ LISTA"

Write-Step "Esperando a que PostgreSQL esté disponible..."

$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    try {
        docker-compose exec -T db pg_isready -U admin | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Base de datos lista"
            break
        }
    } catch {}
    
    $attempt++
    if ($attempt % 5 -eq 0) {
        Write-Host "  Intento $attempt/$maxAttempts..." -ForegroundColor Yellow
    }
    
    Start-Sleep -Seconds 1
}

if ($attempt -eq $maxAttempts) {
    Write-Error-Custom "La base de datos tardó demasiado en iniciarse"
    exit 1
}

# PASO 6: Ejecutar migraciones
Write-Header "PASO 6: EJECUTAR MIGRACIONES DE DJANGO"

Write-Step "Ejecutando migraciones..."

docker-compose exec -T web python manage.py migrate

if ($LASTEXITCODE -eq 0) {
    Write-Success "Migraciones ejecutadas"
} else {
    Write-Warning-Custom "Advertencia: Algunas migraciones pueden no haberse ejecutado"
}

# PASO 7: Información final
Write-Header "✨ INICIALIZACIÓN COMPLETADA"

Write-Host "🔗 URLs de acceso:" -ForegroundColor White
Write-Host "   🌐 Frontend:      http://localhost:5173" -ForegroundColor Cyan
Write-Host "   🔌 API Django:    http://localhost:8000" -ForegroundColor Cyan
Write-Host "   👨‍💼 Admin:         http://localhost:8000/admin" -ForegroundColor Cyan
Write-Host "   📊 SonarQube:     http://localhost:9000" -ForegroundColor Cyan
Write-Host "   🤖 AI Service:    http://localhost:8001" -ForegroundColor Cyan

Write-Host ""
Write-Host "📝 Credenciales de prueba:" -ForegroundColor White
Write-Host "   Usuario:     testuser" -ForegroundColor Cyan
Write-Host "   Contraseña:  changeme" -ForegroundColor Cyan

Write-Host ""
Write-Host "📋 Comandos útiles:" -ForegroundColor White
Write-Host "   Ver logs:              docker-compose logs -f web" -ForegroundColor Cyan
Write-Host "   Acceder a shell:       docker-compose exec web python manage.py shell" -ForegroundColor Cyan
Write-Host "   Detener servicios:     docker-compose down" -ForegroundColor Cyan
Write-Host "   Ver estado:            docker-compose ps" -ForegroundColor Cyan

Write-Host ""
Write-Host "✅ El proyecto está completamente configurado y listo para usar." -ForegroundColor Green
Write-Host ""
