# Rate Limiting Configuration

# Rate limit definitions for different endpoints
RATE_LIMITS = {
    # Autenticación - muy restrictivo por seguridad
    'login': '5/h',  # 5 intentos por hora
    'register': '3/h',  # 3 registros por hora
    'auth_reset': '3/h',  # 3 intentos de reset por hora
    'refresh_token': '10/h',  # 10 refreshes por hora
    
    # API Endpoints - moderado
    'file_upload': '20/h',  # 20 archivos por hora
    'user_profile': '30/h',  # 30 requests por hora
    'patient_data': '50/h',  # 50 requests por hora
}

# Por IP, usuario, etc.
RATE_LIMIT_KEYS = {
    'login': 'ip',  # Por dirección IP
    'register': 'ip',
    'refresh_token': 'user_id',  # Por usuario autenticado
    'auth_reset': 'ip',  # Rate limit de reset por IP
    'file_upload': 'user_id',
}
