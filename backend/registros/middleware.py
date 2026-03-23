"""
Middleware personalizado para manejar CORS preflight OPTIONS requests
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
