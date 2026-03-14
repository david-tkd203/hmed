from django.db import models
from django.contrib.auth.models import User

class RegistroClinico(models.Model):
    paciente = models.ForeignKey(User, on_delete=models.CASCADE)
    especialidad = models.CharField(max_length=100)
    clinica = models.CharField(max_length=200)
    fecha_consulta = models.DateField()
    diagnostico = models.TextField()
    documento_respaldo = models.FileField(upload_to='clinico/%Y/%m/', null=True, blank=True)
    creado_en = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.especialidad} - {self.fecha_consulta}"

class Medicamento(models.Model):
    registro = models.ForeignKey(RegistroClinico, on_delete=models.CASCADE, related_name='medicamentos')
    nombre = models.CharField(max_length=200)
    miligramos = models.FloatField(null=True, blank=True)
    frecuencia_horas = models.IntegerField()
    fecha_inicio = models.DateField()
    duracion_dias = models.IntegerField()
    es_cronico = models.BooleanField(default=False)
    raw_extraction_data = models.JSONField(null=True, blank=True)

    def __str__(self):
        return self.nombre