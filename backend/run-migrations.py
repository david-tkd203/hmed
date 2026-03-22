#!/usr/bin/env python
"""
Script para ejecutar migraciones de Django de forma segura y controlada.
Puede ser ejecutado en cualquier momento para sincronizar la base de datos.

Uso:
    python manage.py shell < run-migrations.py
    
O desde Docker:
    docker-compose exec web python run-migrations.py
"""

import os
import sys
import django
from pathlib import Path

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Hmed.settings')
django.setup()

from django.core.management import call_command
from django.db import connection
from django.contrib.auth.models import User

print("\n" + "=" * 60)
print("🔄 GESTOR DE MIGRACIONES - HISTORICO CLINICO")
print("=" * 60 + "\n")

# ============================================
# 1. VERIFICAR CONEXION A BASE DE DATOS
# ============================================
print("📊 Verificando conexión a base de datos...")
try:
    with connection.cursor() as cursor:
        cursor.execute("SELECT version();")
        db_version = cursor.fetchone()[0]
    print(f"✅ Conexión exitosa")
    print(f"   PostgreSQL: {db_version.split(',')[0]}")
except Exception as e:
    print(f"❌ Error de conexión: {e}")
    sys.exit(1)

print("")

# ============================================
# 2. EJECUTAR MIGRACIONES
# ============================================
print("🔄 Ejecutando migraciones...")
try:
    # Mostrar migraciones pendientes
    call_command('showmigrations', verbosity=1)
    print("")
    
    # Aplicar todas las migraciones
    call_command('migrate', verbosity=2)
    print("\n✅ Migraciones completadas exitosamente")
except Exception as e:
    print(f"\n❌ Error al ejecutar migraciones: {e}")
    sys.exit(1)

print("")

# ============================================
# 3. VERIFICAR SUPERUSUARIOS
# ============================================
print("👤 Verificando superusuarios...")
admin_count = User.objects.filter(is_superuser=True).count()
print(f"   Total de superusuarios: {admin_count}")

superusers = User.objects.filter(is_superuser=True).values_list('username', 'email')
for username, email in superusers:
    print(f"   ✓ {username} ({email})")

print("")

# ============================================
# 4. CREAR USUARIO DE PRUEBA SI NO EXISTE
# ============================================
TEST_USERNAME = os.getenv('TEST_USERNAME', 'testuser')
TEST_PASSWORD = os.getenv('TEST_PASSWORD', 'changeme')
TEST_EMAIL = os.getenv('TEST_EMAIL', 'test@example.local')

print(f"🔐 Configurando usuario de prueba: '{TEST_USERNAME}'...")
try:
    user, created = User.objects.get_or_create(
        username=TEST_USERNAME,
        defaults={
            'email': TEST_EMAIL,
            'is_superuser': True,
            'is_staff': True,
        }
    )
    
    # Actualizar contraseña siempre
    user.set_password(TEST_PASSWORD)
    user.is_superuser = True
    user.is_staff = True
    user.save()
    
    if created:
        print(f"✅ Usuario creado: {TEST_USERNAME}")
    else:
        print(f"✅ Usuario actualizado: {TEST_USERNAME}")
        
    print(f"   Email: {user.email}")
    print(f"   Superusuario: {'Sí' if user.is_superuser else 'No'}")
    print(f"   Staff: {'Sí' if user.is_staff else 'No'}")
    
except Exception as e:
    print(f"❌ Error al crear usuario: {e}")
    sys.exit(1)

print("")

# ============================================
# 5. RESUMEN FINAL
# ============================================
print("=" * 60)
print("✨ INICIALIZACIÓN COMPLETADA EXITOSAMENTE")
print("=" * 60)
print("\n📝 Resumen:")
print(f"   ✓ Base de datos: Conectada")
print(f"   ✓ Migraciones: Aplicadas")
print(f"   ✓ Usuario de prueba: ${TEST_USERNAME}")
print(f"   ✓ Credenciales de prueba:")
print(f"      Usuario: {TEST_USERNAME}")
print(f"      Contraseña: {TEST_PASSWORD}")
print(f"      Email: {TEST_EMAIL}")
print("\n🚀 La aplicación está lista para usar.\n")
