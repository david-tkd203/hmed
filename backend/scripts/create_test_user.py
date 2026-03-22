"""
Script para crear un usuario de prueba en HMED
Uso: python manage.py shell < scripts/create_test_user.py
O: python manage.py shell -c "exec(open('scripts/create_test_user.py').read())"
"""

import os
from django.contrib.auth.models import User
from registros.models import Paciente
from datetime import date

# Datos del usuario de prueba (usar variables de entorno, con defaults)
username = os.getenv('TEST_USERNAME', 'demo')
email = os.getenv('TEST_EMAIL', 'demo@example.local')
password = os.getenv('TEST_PASSWORD', 'changeme')
first_name = 'Test'
last_name = 'User'

try:
    # Verificar si el usuario ya existe
    if User.objects.filter(username=username).exists():
        print(f"✓ El usuario '{username}' ya existe")
    else:
        # Crear usuario
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name
        )
        print(f"✓ Usuario '{username}' creado correctamente")
        
        # Crear perfil de paciente
        paciente = Paciente.objects.create(
            usuario=user,
            numero_cedula='0000000000',
            genero='M',
            fecha_nacimiento=date(1990, 1, 1),
            ciudad='Local',
            pais='Local'
        )
        print(f"✓ Perfil de paciente creado correctamente")
        print(f"\nCredenciales de acceso:")
        print(f"  Usuario: {username}")
        print(f"  Email: {email}")
        print(f"  Nota: Credenciales definidas en variables de entorno")

except Exception as e:
    print(f"✗ Error: {str(e)}")
    import sys
    sys.exit(1)
