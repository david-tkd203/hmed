import os
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from registros.models import Paciente
from datetime import date
import hashlib

class Command(BaseCommand):
    help = 'Crea un usuario de prueba para HMED'

    def add_arguments(self, parser):
        parser.add_argument(
            '--username',
            type=str,
            default=os.getenv('TEST_USERNAME', 'demo'),
            help='Nombre de usuario'
        )
        parser.add_argument(
            '--email',
            type=str,
            default=os.getenv('TEST_EMAIL', 'demo@example.local'),
            help='Email del usuario'
        )
        parser.add_argument(
            '--password',
            type=str,
            default=os.getenv('TEST_PASSWORD', 'changeme'),
            help='Contraseña'
        )

    def handle(self, *args, **options):
        username = options['username']
        email = options['email']
        password = options['password']

        try:
            # Crear o actualizar usuario
            user, created = User.objects.get_or_create(
                username=username,
                defaults={
                    'email': email,
                    'first_name': 'Test',
                    'last_name': 'User'
                }
            )
            
            # Actualizar contraseña
            user.set_password(password)
            user.save()
            
            if created:
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Usuario "{username}" creado correctamente')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'✓ Usuario "{username}" ya existe, contraseña actualizada')
                )
            
            # Crear o actualizar perfil de paciente
            # Generar cédula única basada en el username
            cedula_hash = hashlib.md5(username.encode()).hexdigest()[:10]
            cedula_unica = cedula_hash.lstrip('0') or '0000000001'  # Asegurar que no esté vacío
            
            paciente, created_pac = Paciente.objects.get_or_create(
                usuario=user,
                defaults={
                    'numero_cedula': cedula_unica,
                    'genero': 'M',
                    'fecha_nacimiento': date(1990, 1, 1),
                    'ciudad': 'Test City',
                    'pais': 'Test Country'
                }
            )
            
            if created_pac:
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Perfil de paciente creado (Cédula: {cedula_unica})')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'✓ Perfil de paciente ya existe (Cédula: {paciente.numero_cedula})')
                )
            
            self.stdout.write('\nCredenciales:')
            self.stdout.write(f'  Usuario: {username}')
            self.stdout.write(f'  Email: {email}')
            self.stdout.write(f'  Contraseña: {password}')

        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Error: {str(e)}')
            )
