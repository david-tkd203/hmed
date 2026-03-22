#!/bin/bash

# Script para ejecutar análisis de SonarQube en Linux/Mac
# Requiere: sonar-scanner instalado y en PATH
#           SonarQube servidor corriendo en http://localhost:9000

echo "========================================"
echo "  HMED - Análisis de Código con SonarQube"
echo "========================================"
echo ""

# Verificar si sonar-scanner está instalado
if ! command -v sonar-scanner &> /dev/null; then
    echo "[ERROR] sonar-scanner no encontrado en PATH"
    echo ""
    echo "Instalar sonar-scanner:"
    echo "1. Descargar: https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/"
    echo "2. Extraer el archivo"
    echo "3. Agregar a PATH: export PATH=\$PATH:/path/to/sonar-scanner/bin"
    echo ""
    exit 1
fi

echo "[✓] sonar-scanner encontrado"
echo ""

# Verificar conexión a SonarQube
echo "[*] Verificando conexión a SonarQube..."
if ! curl -s http://localhost:9000/api/system/health > /dev/null 2>&1; then
    echo "[ERROR] No se puede conectar a SonarQube en http://localhost:9000"
    echo ""
    echo "Asegúrate de que SonarQube está ejecutándose:"
    echo "  docker-compose up -d sonarqube"
    echo ""
    exit 1
fi

echo "[✓] SonarQube está activo"
echo ""

# Ejecutar análisis completo
echo "[*] Iniciando análisis del proyecto..."
echo ""

sonar-scanner \
    -Dsonar.projectBaseDir=. \
    -Dsonar.host.url=http://localhost:9000 \
    -Dsonar.login=admin \
    -Dsonar.password=admin

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] El análisis falló"
    exit 1
fi

echo ""
echo "========================================"
echo "  ✓ Análisis completado exitosamente"
echo "========================================"
echo ""
echo "Resultados disponibles en:"
echo "  http://localhost:9000/projects"
echo ""
