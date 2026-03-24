#!/usr/bin/env bash
# Script para validar cabeceras de seguridad en múltiples endpoints
# Uso: ./test-security-headers.sh [URL_BASE]

set -e

URL_BASE="${1:-http://localhost:8000}"
ENDPOINTS=(
    "/api/docs/"
    "/api/schema/"
    "/api/health/"
    "/admin/"
)

echo "==================================================================="
echo "PRUEBA DE CABECERAS DE SEGURIDAD"
echo "==================================================================="
echo "URL Base: $URL_BASE"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_header() {
    local endpoint=$1
    local header=$2
    local expected=$3
    
    local response=$(curl -sI "$URL_BASE$endpoint" 2>/dev/null || echo "ERROR")
    
    if echo "$response" | grep -qi "^$header:"; then
        local value=$(echo "$response" | grep -i "^$header:" | cut -d' ' -f2-)
        
        if [[ -z "$expected" ]] || echo "$value" | grep -qi "$expected"; then
            echo -e "${GREEN}✅${NC} $header: $value"
            return 0
        else
            echo -e "${YELLOW}⚠️ ${NC} $header: $value (esperado: $expected)"
            return 1
        fi
    else
        echo -e "${RED}❌${NC} $header: NO PRESENTE"
        return 1
    fi
}

for endpoint in "${ENDPOINTS[@]}"; do
    echo "-------------------------------------------------------------------"
    echo "Endpoint: $endpoint"
    echo "-------------------------------------------------------------------"
    
    # Status
    status=$(curl -sI "$URL_BASE$endpoint" 2>/dev/null | head -1)
    echo "Status: $status"
    echo ""
    
    # Cabeceras de seguridad
    check_header "$endpoint" "Content-Security-Policy" "default-src" || true
    check_header "$endpoint" "Permissions-Policy" "camera=()" || true
    check_header "$endpoint" "Referrer-Policy" "strict-origin-when-cross-origin" || true
    check_header "$endpoint" "Cross-Origin-Resource-Policy" "same-origin" || true
    check_header "$endpoint" "X-Content-Type-Options" "nosniff" || true
    check_header "$endpoint" "X-XSS-Protection" "1; mode=block" || true
    check_header "$endpoint" "X-Frame-Options" "DENY" || true
    
    echo ""
done

echo "==================================================================="
echo "RESUMEN DE CABECERAS ENCONTRADAS"
echo "==================================================================="
echo ""

# Todas las cabeceras únicas encontradas
curl -sI "$URL_BASE/api/docs/" 2>/dev/null | head -30

echo ""
echo "==================================================================="
echo "Para validación automática, ejecutar:"
echo "  python validate-security-headers.py --url $URL_BASE/api/docs/"
echo "==================================================================="
