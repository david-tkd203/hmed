from django_ratelimit.decorators import ratelimit as django_ratelimit_decorator
from rest_framework.response import Response
from rest_framework import status
import functools
from django_ratelimit.core import get_usage
import re

def custom_ratelimit(rate, key='ip', method=None):
    """
    Decorador personalizado de rate limiting que retorna respuestas JSON apropiadas
    
    Args:
        rate: string con formato "5/h", "10/m", etc.
        key: 'ip' o 'user_id'
        method: 'GET', 'POST', etc.
    """
    def decorator(view_func):
        @functools.wraps(view_func)
        def wrapped_view(request, *args, **kwargs):
            # Construir la clave de rate limit
            if key == 'ip':
                ratelimit_key = get_client_ip(request)
            elif key == 'user_id':
                if request.user.is_authenticated:
                    ratelimit_key = f"user_{request.user.id}"
                else:
                    ratelimit_key = get_client_ip(request)
            else:
                ratelimit_key = key
            
            # Aplicar rate limit
            ratelimit_key_full = f"{ratelimit_key}:{view_func.__name__}"
            
            # Usar django-ratelimit
            try:
                # Obtener el decorador de ratelimit
                decorated = django_ratelimit_decorator(
                    key=f"'static:{ratelimit_key_full}'",
                    rate=rate,
                    method=method,
                    block=False
                )(view_func)
                
                response = decorated(request, *args, **kwargs)
                
                # Verificar si fue bloqueado
                getattr(request, 'limited', False)
                if request.limited:
                    return Response(
                        {
                            'error': 'Demasiados intentos. Por favor, intenta más tarde.',
                            'detail': f'Límite de {rate} excedido',
                            'retry_after': f'Por favor, intenta en una hora'
                        },
                        status=status.HTTP_429_TOO_MANY_REQUESTS,
                        headers={'Retry-After': '3600'}
                    )
                
                return response
            except Exception as e:
                print(f"Rate limit error: {e}")
                return view_func(request, *args, **kwargs)
        
        return wrapped_view
    return decorator


def get_client_ip(request):
    """Obtener la IP del cliente real (incluyendo X-Forwarded-For)"""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip


# Configuración de mensajes de error personalizados
RATE_LIMIT_MESSAGES = {
    'login': {
        'error': 'Demasiados intentos de login',
        'detail': 'Has excedido el límite de 5 intentos por hora',
        'retry_after': 'Por favor, intenta de nuevo en una hora'
    },
    'register': {
        'error': 'Demasiados registros',
        'detail': 'Has excedido el límite de 3 registros por hora',
        'retry_after': 'Por favor, intenta de nuevo en una hora'
    },
    'file_upload': {
        'error': 'Demasiadas subidas',
        'detail': 'Has excedido el límite de 20 subidas por hora',
        'retry_after': 'Por favor, intenta de nuevo'
    },
}
