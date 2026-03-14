"""
Script para crear un usuario de prueba en HMED
Uso: python manage.py shell < scripts/create_test_user.py
"""

from django.contrib.auth.models import User
from registros.models import Paciente
from datetime import date

# Datos del usuario de prueba
username = 'demo'
email = 'demo@hmed.com'
password = '123456'
first_name = 'Demo'
last_name = 'Usuario'

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
            numero_cedula='1234567890',
            genero='M',
            fecha_nacimiento=date(1990, 1, 1),
            ciudad='Bogotá',
            pais='Colombia'
        )
        print(f"✓ Perfil de paciente creado correctamente")
        print(f"\nCredenciales de acceso:")
        print(f"  Usuario: {username}")
        print(f"  Contraseña: {password}")
        print(f"  Email: {email}")

except Exception as e:
    print(f"✗ Error: {str(e)}")
