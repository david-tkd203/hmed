from django.contrib import admin
from django.urls import path, include
from rest_framework import routers
from rest_framework_simplejwt.views import TokenRefreshView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView
from registros.views import (
    MedicamentoViewSet, 
    login_view, 
    register_view, 
    logout_view, 
    refresh_token_view, 
    update_paciente_profile,
    validate_file_view,
    upload_registro_view
)

router = routers.DefaultRouter()
router.register(r'medicamentos', MedicamentoViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    
    # =============== AUTENTICACIÓN JWT ===============
    path('api/login/', login_view, name='login'),
    path('api/register/', register_view, name='register'),
    path('api/logout/', logout_view, name='logout'),
    path('api/token/refresh/', refresh_token_view, name='token_refresh'),
    
    # =============== PERFIL DE USUARIO ===============
    path('api/paciente/profile/', update_paciente_profile, name='update_paciente_profile'),
    
    # =============== VALIDACIÓN DE ARCHIVOS ===============
    path('api/file/validate/', validate_file_view, name='validate_file'),
    
    # =============== REGISTROS CLÍNICOS ===============
    path('api/registro/upload/', upload_registro_view, name='upload_registro'),
    
    # =============== DOCUMENTACIÓN API (SWAGGER/OPENAPI) ===============
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/swagger/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/docs/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]