from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):

    dependencies = [
        ('registros', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Paciente',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('numero_cedula', models.CharField(max_length=20, unique=True)),
                ('genero', models.CharField(choices=[('M', 'Masculino'), ('F', 'Femenino'), ('O', 'Otro')], max_length=1)),
                ('fecha_nacimiento', models.DateField()),
                ('telefono', models.CharField(blank=True, max_length=15, null=True)),
                ('direccion', models.CharField(blank=True, max_length=255, null=True)),
                ('ciudad', models.CharField(blank=True, max_length=100, null=True)),
                ('pais', models.CharField(default='Colombia', max_length=100)),
                ('alergias', models.TextField(blank=True, help_text='Alergias conocidas del paciente', null=True)),
                ('enfermedades_cronicas', models.TextField(blank=True, help_text='Enfermedades crónicas existentes', null=True)),
                ('foto_perfil', models.ImageField(blank=True, null=True, upload_to='perfiles/%Y/%m/')),
                ('creado_en', models.DateTimeField(auto_now_add=True)),
                ('actualizado_en', models.DateTimeField(auto_now=True)),
                ('usuario', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='paciente', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Paciente',
                'verbose_name_plural': 'Pacientes',
            },
        ),
    ]
