#!/bin/bash

# Script para ejecutar análisis SonarQB
# Uso: ./run-sonar-analysis.sh

echo "🔍 Iniciando análisis SonarQB..."
echo "Esperando a que SonarQB esté listo (2-3 minutos)..."

# Esperar a que SonarQB esté disponible
for i in {1..30}; do
  if docker-compose exec -T sonarqube sh -c 'curl -s http://localhost:9000/api/system/status | grep UP' > /dev/null 2>&1; then
    echo "✅ SonarQB está listo"
    break
  fi
  echo "⏳ Intento $i/30..."
  sleep 6
done

# Ejecutar análisis con sonar-scanner
echo ""
echo "📊 Analizando código..."

# Crear token en SonarQB (si es necesario)
# Por ahora usamos credenciales por defecto: admin/admin

docker run --rm \
  --network="historicoclinico_hmed_network" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=historico-clinico \
  -Dsonar.sources=/usr/src/backend/registros,/usr/src/frontend/src \
  -Dsonar.host.url=http://sonarqube:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=admin

echo ""
echo "✅ Análisis completado"
echo "📈 Ver resultados en: http://localhost:9000"
echo ""
echo "Credenciales por defecto:"
echo "  Usuario: admin"
echo "  Contraseña: admin"
