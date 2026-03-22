import os
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from registros.models import Paciente
from datetime import date

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
            if User.objects.filter(username=username).exists():
                self.stdout.write(
                    self.style.WARNING(f"✓ El usuario '{username}' ya existe")
                )
            else:
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    password=password,
                    first_name='Test',
                    last_name='User'
                )
                
                paciente = Paciente.objects.create(
                    usuario=user,
                    numero_cedula='0000000000',
                    genero='M',
                    fecha_nacimiento=date(1990, 1, 1),
                    ciudad='Test City',
                    pais='Test Country'
                )
                
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Usuario "{username}" creado correctamente')
                )
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Perfil de paciente creado')
                )
                self.stdout.write('\nDetalles:')
                self.stdout.write(f'  Usuario: {username}')
                self.stdout.write(f'  Email: {email}')
                self.stdout.write(f'  Nota: Contraseña definida en variable de entorno TEST_PASSWORD')

        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Error: {str(e)}')
            )
