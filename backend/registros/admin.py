from django.contrib import admin
from .models import RegistroClinico, Medicamento, Paciente

@admin.register(Paciente)
class PacienteAdmin(admin.ModelAdmin):
    list_display = ('numero_cedula', 'usuario', 'genero', 'ciudad', 'creado_en')
    search_fields = ('usuario__first_name', 'usuario__last_name', 'numero_cedula', 'email')
    list_filter = ('genero', 'ciudad', 'creado_en')
    readonly_fields = ('creado_en', 'actualizado_en')

@admin.register(RegistroClinico)
class RegistroClinicoAdmin(admin.ModelAdmin):
    list_display = ('especialidad', 'clinica', 'fecha_consulta', 'paciente')
    search_fields = ('especialidad', 'diagnostico')

@admin.register(Medicamento)
class MedicamentoAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'miligramos', 'frecuencia_horas', 'es_cronico')