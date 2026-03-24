"""
Middleware personalizado para manejar CORS preflight OPTIONS requests
y aplicar cabeceras de seguridad hardened (OWASP)
"""
from django.http import HttpResponse
from django.utils.deprecation import MiddlewareMixin


class NoRedirectOptionsMiddleware(MiddlewareMixin):
    """
    Intercepta solicitudes OPTIONS (CORS preflight) y devuelve 200 OK
    inmediatamente con headers CORS, antes de que CommonMiddleware
    intente redirigir.
    """
    
    def process_request(self, request):
        if request.method != 'OPTIONS':
            return None
        
        # Crear respuesta 200 OK con headers CORS
        response = HttpResponse()
        response.status_code = 200
        
        origin = request.META.get('HTTP_ORIGIN', '*')
        response['Access-Control-Allow-Origin'] = origin
        response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
        response['Access-Control-Allow-Headers'] = (
            'accept, accept-encoding, authorization, content-type, '
            'dnt, origin, user-agent, x-csrftoken, x-requested-with'
        )
        response['Access-Control-Allow-Credentials'] = 'true'
        response['Access-Control-Max-Age'] = '3600'
        
        return response


class SecurityHeadersMiddleware(MiddlewareMixin):
    """
    Añade cabeceras de seguridad adicionales no soportadas por django-csp
    - Permissions-Policy: Desactiva APIs no usadas
    - Cross-Origin-Resource-Policy: Restrict CORP a same-origin
    - Server: Oculta versión de servidor
    """
    
    def process_response(self, request, response):
        # ============ PERMISSIONS POLICY (Feature Policy) ============
        # Desactiva APIs del navegador que no usamos
        response['Permissions-Policy'] = (
            'accelerometer=(), '
            'camera=(), '
            'geolocation=(), '
            'gyroscope=(), '
            'magnetometer=(), '
            'microphone=(), '
            'payment=(), '
            'usb=()'
        )
        
        # ============ CROSS-ORIGIN-RESOURCE-POLICY ============
        # Previene que otros sitios carguen recursos: solo same-origin
        response['Cross-Origin-Resource-Policy'] = 'same-origin'
        
        # ============ OCULTAR VERSIÓN DE SERVIDOR ============
        # Eliminar headers que revelan versión de servidor
        if 'Server' in response:
            del response['Server']
        
        # Para WSGI servers (gunicorn, uWSGI, etc.)
        # Se configura mejor en la configuración del servidor
        response['Server'] = 'SecurityServer'
        
        return response
