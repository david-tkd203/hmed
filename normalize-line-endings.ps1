#!/usr/bin/env pwsh
# ============================================
# Normalize Git Line Endings
# ============================================
# Script para normalizar los saltos de línea en el repositorio
# Evita advertencias: "LF will be replaced by CRLF the next time Git touches it"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Normalizando saltos de línea del repositorio" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar si estamos en un repositorio git
if (-not (Test-Path ".git")) {
    Write-Host "❌ No se encontró repositorio git (.git)" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Repositorio git encontrado" -ForegroundColor Green

# 2. Configurar git para normalizar
Write-Host ""
Write-Host "[1/4] Configurando git para autoCRLF..." -ForegroundColor Yellow
git config core.safecrlf false
git config core.autocrlf true

Write-Host "✅ Configuración de git actualizada" -ForegroundColor Green

# 3. Normalizar todos los archivos
Write-Host ""
Write-Host "[2/4] Eliminando índice de git temporal..." -ForegroundColor Yellow
git rm --cached -r .
Write-Host "✅ Índice temporal removido" -ForegroundColor Green

# 4. Re-agregar archivos con normalización
Write-Host ""
Write-Host "[3/4] Re-agregando archivos con líneas normalizadas..." -ForegroundColor Yellow
git reset
git add .
Write-Host "✅ Archivos re-agregados" -ForegroundColor Green

# 5. Verificar cambios
Write-Host ""
Write-Host "[4/4] Estado del repositorio:" -ForegroundColor Yellow
Write-Host ""
git status

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ Normalización completada" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ahora puedes hacer:" -ForegroundColor Green
Write-Host "  git add -A" -ForegroundColor White
Write-Host "  git commit -m 'Normalize line endings'" -ForegroundColor White
Write-Host ""
