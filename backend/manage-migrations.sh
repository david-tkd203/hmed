#!/bin/bash

# Script para ejecutar migraciones en el contenedor Docker
# Uso: docker-compose exec web bash /app/manage-migrations.sh

set -e

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "=================================="
echo "🔄 GESTOR DE MIGRACIONES"
echo "=================================="
echo "⏰ Tiempo: $TIMESTAMP"
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar variables de entorno
echo "📊 Configuración actual:"
echo "   DB_HOST: ${DB_HOST:-db}"
echo "   DB_NAME: ${DB_NAME:-hmed_db}"
echo "   DB_USER: ${DB_USER:-admin}"
echo "   DEBUG: ${DEBUG:-False}"
echo ""

# Ejecutar migraciones
echo "🔄 Aplicando migraciones..."
python manage.py migrate --noinput

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Migraciones aplicadas correctamente${NC}"
else
    echo -e "${RED}❌ Error al aplicar migraciones${NC}"
    exit 1
fi

echo ""

# Crear superusuario de prueba
TEST_USERNAME=${TEST_USERNAME:-testuser}
TEST_PASSWORD=${TEST_PASSWORD:-changeme}
TEST_EMAIL=${TEST_EMAIL:-test@example.local}

echo "👤 Configurando usuario de prueba: $TEST_USERNAME"

python manage.py shell << EOFPYTHON
from django.contrib.auth.models import User

try:
    user, created = User.objects.get_or_create(
        username='$TEST_USERNAME',
        defaults={'email': '$TEST_EMAIL'}
    )
    user.set_password('$TEST_PASSWORD')
    user.is_superuser = True
    user.is_staff = True
    user.save()
    
    if created:
        print('✅ Usuario creado: $TEST_USERNAME')
    else:
        print('✅ Usuario actualizado: $TEST_USERNAME')
except Exception as e:
    print(f'❌ Error: {e}')
EOFPYTHON

echo ""

# Recopilar archivos estáticos
echo "📦 Recopilando archivos estáticos..."
python manage.py collectstatic --noinput --clear > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Archivos estáticos recopilados${NC}"
else
    echo -e "${YELLOW}⚠️  Advertencia: Algunos archivos estáticos no se pudieron recopilar${NC}"
fi

echo ""

# Información de acceso
echo "=================================="
echo "✨ INICIALIZACIÓN COMPLETADA"
echo "=================================="
echo ""
echo "📝 Información de acceso:"
echo "   Usuario: $TEST_USERNAME"
echo "   Contraseña: $TEST_PASSWORD"
echo "   Email: $TEST_EMAIL"
echo ""
echo "🔗 URLs:"
echo "   Django Admin: http://localhost:8000/admin"
echo "   API: http://localhost:8000/api"
echo "   Documentación: http://localhost:8000/api/schema/swagger"
echo ""
