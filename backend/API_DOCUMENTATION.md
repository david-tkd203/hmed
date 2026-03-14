# HMED API - Rate Limiting & Security Documentation

## Sistema de Rate Limiting

El sistema implementa limitaciones de velocidad para proteger contra ataques de fuerza bruta y abuso de API.

### Configuración de Rate Limits por Endpoint

| Endpoint | Método | Límite | Ventana | Clave | Descripción |
|----------|--------|--------|---------|-------|-------------|
| `/api/login/` | POST | 5 | 1 hora | IP | Máximo 5 intentos de login por IP |
| `/api/register/` | POST | 3 | 1 hora | IP | Máximo 3 registros por IP |
| `/api/token/refresh/` | POST | 10 | 1 hora | IP | Máximo 10 refrescos de token por IP |
| `/api/paciente/profile/` | PATCH | 30 | 1 hora | Usuario | Máximo 30 actualizaciones por usuario |
| `/api/file/validate/` | POST | 20 | 1 hora | Usuario | Máximo 20 validaciones de archivo por usuario |
| `/api/registro/upload/` | POST | 20 | 1 hora | Usuario | Máximo 20 subidas de registros por usuario |

### Códigos de Error

#### 429 Too Many Requests

Cuando se excede el límite de rate limit, la API retorna:

```json
{
  "error": "Demasiados intentos de login",
  "detail": "Has excedido el límite de 5 intentos por hora",
  "retry_after": "Por favor, intenta de nuevo en una hora"
}
```

**Headers de respuesta:**
- `Retry-After: 3600` (tiempo en segundos hasta poder hacer otro intento)

---

## Seguridad de Cargas de Archivos

### Validaciones Implementadas

1. **Tamaño de Archivo**
   - Máximo: 10 MB
   - Validado en `validate_file_upload()`

2. **Tipos MIME Permitidos**
   - `application/pdf` - Documentos PDF
   - `image/jpeg` - Imágenes JPEG
   - `image/png` - Imágenes PNG
   - `application/msword` - Documentos Word (.doc)
   - `application/vnd.openxmlformats-officedocument.wordprocessingml.document` - Word (.docx)

3. **Rate Limiting**
   - Máximo 20 subidas por usuario por hora
   - Máximo 20 validaciones por usuario por hora

### Endpoint de Validación

**POST `/api/file/validate/`**

Valida un archivo antes de subirlo sin guardarlo.

**Request:**
```bash
curl -X POST http://localhost:8000/api/file/validate/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "file=@documento.pdf"
```

**Response (válido):**
```json
{
  "valid": true,
  "file_name": "documento.pdf",
  "file_size": "2048.5 KB",
  "message": "Archivo válido y listo para subir"
}
```

**Response (inválido):**
```json
{
  "error": "Tipo de archivo no permitido. Permitidos: PDF, JPG, PNG, DOC, DOCX"
}
```

---

## Documentación API Interactiva

### Acceso a Swagger UI

```
http://localhost:8000/api/docs/swagger/
```

Interfaz interactiva para probar todos los endpoints.

### Acceso a ReDoc

```
http://localhost:8000/api/docs/redoc/
```

Documentación legible de la API.

### Schema OpenAPI (JSON)

```
http://localhost:8000/api/schema/
```

Especificación completa en formato OpenAPI 3.0.

---

## Autenticación JWT

### Flujo de Autenticación

1. **Login**
   - POST `/api/login/` con `username` y `password`
   - Retorna `access_token` (1 hora) y `refresh_token` (7 días)

2. **Uso de Token**
   ```
   Authorization: Bearer <access_token>
   ```

3. **Refresh Token**
   - POST `/api/token/refresh/` con `refresh_token`
   - Retorna nuevo `access_token`

4. **Logout**
   - DELETE `/api/logout/`
   - (Eliminar token del cliente)

### Duración de Tokens

- **Access Token**: 1 hora
- **Refresh Token**: 7 días
- **Rotación**: Habilitada (nuevo refresh genera nuevo access)

### Headers Requeridos

```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
```

---

## Ejemplos de Uso

### 1. Login

```bash
curl -X POST http://localhost:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"123456"}'
```

**Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "username": "demo",
    "email": "demo@hmed.local",
    "first_name": "Demo",
    "last_name": "User"
  },
  "paciente": {...},
  "message": "Login exitoso"
}
```

### 2. Subir Documento Clínico

```bash
curl -X POST http://localhost:8000/api/registro/upload/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -F "documento_respaldo=@documento.pdf" \
  -F "especialidad=Cardiología" \
  -F "clinica=Hospital Central" \
  -F "fecha_consulta=2026-03-14" \
  -F "diagnostico=Hipertensión Arterial"
```

### 3. Actualizar Perfil

```bash
curl -X PATCH http://localhost:8000/api/paciente/profile/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "telefono": "+57 300 1234567",
    "direccion": "Calle 123 #45",
    "ciudad": "Bogotá",
    "alergias": "Penicilina",
    "enfermedades_cronicas": "Diabetes"
  }'
```

### 4. Validar Archivo

```bash
curl -X POST http://localhost:8000/api/file/validate/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -F "file=@documento.pdf"
```

---

## Variables de Entorno

```env
# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=hmed_db
DB_USER=admin
DB_PASSWORD=secret_pass
DB_HOST=db
DB_PORT=5432

# JWT
JWT_ACCESS_LIFETIME=3600  # segundos (1 hora)
JWT_REFRESH_LIFETIME=604800  # segundos (7 días)

# Rate Limiting
RATELIMIT_ENABLE=True
RATELIMIT_USE_CACHE=default
```

---

## Monitoreo de Rate Limits

### Headers de Respuesta Importantes

Cada respuesta incluye información sobre el rate limit:

```
X-RateLimit-Limit: 5
X-RateLimit-Remaining: 3
X-RateLimit-Reset: 1647345600
Retry-After: 3600
```

---

## Mejores Prácticas

### Para Desarrolladores

1. **Manejo de 429**
   - Implementar reintentos exponenciales
   - Respetar header `Retry-After`

2. **Validación Proactiva**
   - Usar endpoint `/api/file/validate/` antes de subir
   - Verificar tamaño localmente

3. **Autenticación**
   - Guardar tokens en sesión segura
   - Refrescar antes de expirarse
   - Limpiar tokens al logout

### Para Usuarios

1. **Límites de Login**
   - Máximo 5 intentos por hora
   - Si fallan, esperar antes de reintentar

2. **Subida de Archivos**
   - Máximo 20 archivos por hora
   - Máximo 10 MB por archivo
   - Formatos permitidos: PDF, JPG, PNG, DOC, DOCX

3. **Seguridad**
   - No compartir access tokens
   - Usar conexión HTTPS en producción
   - Logout cuando termines la sesión

---

## Resolución de Problemas

### Error 429 Too Many Requests

**Causa**: Has excedido el límite de rate limiting

**Solución**:
- Esperar el tiempo indicado en `Retry-After`
- Revisar el error para saber qué límite excediste

### Error 422 Validation Error (Archivo)

**Causa**: Archivo no válido

**Posibles razones**:
- Tamaño > 10 MB
- Tipo MIME no permitido
- Archivo corrupto

**Solución**:
- Usar endpoint `/api/file/validate/` primero
- Verificar que sea un archivo válido

### Error 401 Unauthorized

**Causa**: Token inválido o expirado

**Solución**:
- Hacer login nuevamente
- Usar endpoint `/api/token/refresh/` para refrescar

---

## Estadísticas de API

### Versión: 1.0.0
### Endpoints: 8
### Métodos HTTP: POST, PATCH
### Autenticación: JWT Bearer
### Rate Limiting: Activa
### CORS: Habilitado

---

**Última actualización**: Marzo 14, 2026  
**Versión API**: 1.0.0
