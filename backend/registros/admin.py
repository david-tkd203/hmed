from django.contrib import admin
from .models import RegistroClinico, Medicamento

@admin.register(RegistroClinico)
class RegistroClinicoAdmin(admin.ModelAdmin):
    list_display = ('especialidad', 'clinica', 'fecha_consulta', 'paciente')
    search_fields = ('especialidad', 'diagnostico')

@admin.register(Medicamento)
class MedicamentoAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'miligramos', 'frecuencia_horas', 'es_cronico')