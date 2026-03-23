#!/bin/bash

# Script de inicialización para Django con manejo de errores
set -e

echo "=================================="
echo "🔧 HISTORICO CLINICO - INICIALIZACION"
echo "=================================="
echo ""

# Información de conexión a BD
echo "📊 Configuración de Base de Datos:"
echo "   - HOST: ${DB_HOST:-db}"
echo "   - BD: ${DB_NAME:-hmed_db}"
echo "   - USUARIO: ${DB_USER:-admin}"
echo ""

# Ejecutar migraciones
echo "🔄 Ejecutando migraciones de Django..."
python manage.py migrate --noinput

if [ $? -eq 0 ]; then
    echo "✅ Migraciones completadas exitosamente"
else
    echo "❌ Error al ejecutar migraciones"
    exit 1
fi
echo ""

# Crear usuario de prueba
echo "👤 Configurando usuario de prueba..."
TEST_USERNAME=${TEST_USERNAME:-testuser}
TEST_PASSWORD=${TEST_PASSWORD:-changeme}
TEST_EMAIL=${TEST_EMAIL:-test@example.local}

python manage.py shell << END
from django.contrib.auth.models import User

try:
    if not User.objects.filter(username='$TEST_USERNAME').exists():
        User.objects.create_superuser('$TEST_USERNAME', '$TEST_EMAIL', '$TEST_PASSWORD')
        print(f'✅ Usuario creado: $TEST_USERNAME (Superuser)')
    else:
        user = User.objects.get(username='$TEST_USERNAME')
        user.set_password('$TEST_PASSWORD')
        user.save()
        print(f'✅ Usuario actualizado: $TEST_USERNAME')
except Exception as e:
    print(f'⚠️  Error al crear usuario: {e}')
END
echo ""

# Recolectar archivos estáticos (solo si no existen)
if [ ! -d "staticfiles" ]; then
    echo "📦 Recopilando archivos estáticos..."
    python manage.py collectstatic --noinput
    echo "✅ Archivos estáticos recopilados"
fi
echo ""

# Iniciar servidor Django
echo "🚀 Iniciando servidor Django..."
echo "   - URL: http://0.0.0.0:8000"
echo "   - Modo: Producción (sin auto-reload de TensorFlow)"
echo ""
python manage.py runserver 0.0.0.0:8000 --noreload

