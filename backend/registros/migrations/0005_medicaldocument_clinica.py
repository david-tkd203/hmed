# Generated migration to add clinica field to MedicalDocument

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('registros', '0004_medicaldocument'),
    ]

    operations = [
        migrations.AddField(
            model_name='medicaldocument',
            name='clinica',
            field=models.CharField(
                blank=True,
                help_text='Clínica o centro médico',
                max_length=200,
                null=True
            ),
        ),
    ]
