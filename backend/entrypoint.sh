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

python manage.py shell << 'PYEOF'
from django.contrib.auth.models import User
from registros.models import Paciente
from datetime import date
import hashlib

test_username = ''"${TEST_USERNAME}"''
test_email = ''"${TEST_EMAIL}"''
test_password = ''"${TEST_PASSWORD}"''

try:
    # Crear o actualizar usuario
    user, created = User.objects.get_or_create(
        username=test_username,
        defaults={
            'email': test_email,
            'first_name': 'Usuario',
            'last_name': 'Prueba'
        }
    )
    
    # Actualizar contraseña
    user.set_password(test_password)
    user.save()
    
    if created:
        print(f'✅ Usuario creado: {test_username}')
    else:
        print(f'✅ Usuario actualizado: {test_username}')
    
    # Generar cédula única basada en el username
    cedula_hash = hashlib.md5(test_username.encode()).hexdigest()[:10]
    cedula_unica = cedula_hash.lstrip('0') or '0000000001'
    
    # Crear o actualizar perfil de paciente
    paciente, created_pac = Paciente.objects.get_or_create(
        usuario=user,
        defaults={
            'numero_cedula': cedula_unica,
            'genero': 'M',
            'fecha_nacimiento': date(1990, 1, 1),
            'ciudad': 'Sistema',
            'pais': 'Colombia'
        }
    )
    
    if created_pac:
        print(f'✅ Perfil de paciente creado (Cédula: {cedula_unica})')
    else:
        print(f'✅ Perfil de paciente verificado (Cédula: {paciente.numero_cedula})')
        
except Exception as e:
    print(f'⚠️  Error al crear usuario/paciente: {e}')
PYEOF
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

