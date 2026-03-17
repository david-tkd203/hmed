from django.db import models
from django.contrib.auth.models import User

class Paciente(models.Model):
    """Modelo extendido de usuario para pacientes"""
    GENERO_CHOICES = [
        ('M', 'Masculino'),
        ('F', 'Femenino'),
        ('O', 'Otro'),
    ]
    
    usuario = models.OneToOneField(User, on_delete=models.CASCADE, related_name='paciente')
    numero_cedula = models.CharField(max_length=20, unique=True)
    genero = models.CharField(max_length=1, choices=GENERO_CHOICES)
    fecha_nacimiento = models.DateField()
    telefono = models.CharField(max_length=15, blank=True, null=True)
    direccion = models.CharField(max_length=255, blank=True, null=True)
    ciudad = models.CharField(max_length=100, blank=True, null=True)
    pais = models.CharField(max_length=100, default='Colombia')
    alergias = models.TextField(blank=True, null=True, help_text='Alergias conocidas del paciente')
    enfermedades_cronicas = models.TextField(blank=True, null=True, help_text='Enfermedades crónicas existentes')
    foto_perfil = models.ImageField(upload_to='perfiles/%Y/%m/', null=True, blank=True)
    creado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.usuario.first_name} {self.usuario.last_name} ({self.numero_cedula})"

    class Meta:
        verbose_name = "Paciente"
        verbose_name_plural = "Pacientes"


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

    class Meta:
        ordering = ['-fecha_consulta']

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


class MedicalDocument(models.Model):
    """Modelo para almacenar documentos médicos generales (radiografías, análisis, etc.)"""
    TIPO_DOCUMENTO_CHOICES = [
        ('radiografia', 'Radiografía'),
        ('analisis', 'Análisis/Laboratorio'),
        ('ecografia', 'Ecografía'),
        ('tomografia', 'Tomografía'),
        ('resonancia', 'Resonancia Magnética'),
        ('informe', 'Informe Médico'),
        ('receta', 'Receta Médica'),
        ('otro', 'Otro'),
    ]

    usuario = models.ForeignKey(User, on_delete=models.CASCADE, related_name='documentos_medicos')
    tipo_documento = models.CharField(max_length=20, choices=TIPO_DOCUMENTO_CHOICES, default='otro')
    nombre = models.CharField(max_length=255)
    descripcion = models.TextField(blank=True, null=True)
    archivo = models.FileField(upload_to='documentos_medicos/%Y/%m/%d/')
    fecha_documento = models.DateField(blank=True, null=True, help_text='Fecha del documento original')
    especialidad = models.CharField(max_length=100, blank=True, null=True)
    medico_emisor = models.CharField(max_length=200, blank=True, null=True)
    contenido_extraido = models.TextField(blank=True, null=True, help_text='Contenido extraído mediante OCR/IA')
    ia_analisis = models.JSONField(blank=True, null=True, help_text='Análisis IA (MedSigLIP, MedGemma)')
    creado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.nombre} - {self.usuario.first_name}"

    class Meta:
        ordering = ['-fecha_documento', '-creado_en']
        indexes = [
            models.Index(fields=['usuario', '-creado_en']),
            models.Index(fields=['tipo_documento']),
        ]