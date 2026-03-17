#!/bin/bash

# Script para ejecutar análisis SonarQB
# Uso: ./run-sonar-analysis.sh [TOKEN]
# Ejemplo: ./run-sonar-analysis.sh sqa_xxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Si no se proporciona token, usar el generado en SonarQB
SONAR_TOKEN="${1:-sqa_6610dc854e1e84abbfa0bd6f21afa3c277907eb4}"

# Validar que se proporcionó un token
if [ -z "$SONAR_TOKEN" ] || [ "$SONAR_TOKEN" = "-h" ] || [ "$SONAR_TOKEN" = "--help" ]; then
  echo "❌ Error: No se proporcionó token de SonarQB"
  echo ""
  echo "Uso: bash run-sonar-analysis.sh <TOKEN>"
  echo ""
  echo "Para obtener un token:"
  echo "1. Abre http://localhost:9000"
  echo "2. My Account → Security → Tokens"
  echo "3. Click 'Generate' y copia el token"
  echo "4. Ejecuta: bash run-sonar-analysis.sh <tu-token>"
  exit 1
fi

echo "🔍 Iniciando análisis SonarQB..."
echo "🔐 Token: ${SONAR_TOKEN:0:10}...***"
echo ""
echo "📊 Analizando código..."
echo "   Proyecto: historico-clinico"
echo "   Fuentes: backend/registros, frontend/src"
echo "   Host: http://sonarqube:9000"
echo ""
echo "⏳ Esto puede tardar 1-3 minutos..."
echo ""

# Ejecutar análisis con sonar-scanner usando TOKEN
# Sin esperar a que esté listo - Docker lo manejará
docker run --rm \
  --network="historicoclinico_hmed_network" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=historico-clinico \
  -Dsonar.sources=/usr/src/backend/registros,/usr/src/frontend/src \
  -Dsonar.host.url=http://sonarqube:9000 \
  -Dsonar.token="$SONAR_TOKEN"

RESULT=$?

echo ""
if [ $RESULT -eq 0 ]; then
  echo "✅ Análisis completado EXITOSAMENTE"
  echo ""
  echo "📈 Dashboard: http://localhost:9000"
  echo "   Proyecto: Histórico Clínico"
  echo ""
  echo "Métricas:"
  echo "  🔴 Bugs - Errores reales"
  echo "  🟡 Code Smells - Malas prácticas"
  echo "  🔐 Security - Vulnerabilidades"
  echo "  📊 Deuda Técnica"
else
  echo "❌ Error en análisis (código: $RESULT)"
  echo ""
  echo "Posibles soluciones:"
  echo "1. Verifica que SonarQB está corriendo: docker-compose ps"
  echo "2. Verifica el token: http://localhost:9000/account/security/"
  echo "3. Verifica logs: docker logs sonarqube | tail -20"
fi

exit $RESULT
