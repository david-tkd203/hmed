# 🚀 Guía de Despliegue - Historico Clinico

## Índice
1. [Arquitectura General](#arquitectura-general)
2. [Requisitos Previos](#requisitos-previos)
3. [Instalación y Ejecución](#instalación-y-ejecución)
4. [Servicios Disponibles](#servicios-disponibles)
5. [Credenciales](#credenciales)
6. [Solución de Problemas](#solución-de-problemas)

---

## Arquitectura General

El proyecto está compuesto por **5 servicios Docker** que se comunican a través de una red bridge compartida:

```
┌─────────────────────────────────────────────────────────────┐
│                    HISTORICO CLINICO APP                     │
└─────────────────────────────────────────────────────────────┘
         │                    │                │
    ┌────▼────┐          ┌────▼────┐      ┌────▼────┐
    │ Frontend │          │  Django │      │   AI    │
    │(Vite)   │          │  (API)  │      │ Service │
    │   5173  │          │  8000   │      │  8001   │
    └────┬────┘          └────┬────┘      └────┬────┘
         │                    │                │
         └────────────────────┼────────────────┘
                              │
                         ┌────▼────┐
                         │ PostgreSQL
                         │   5432
                         └─────────┘
                    
    SonarQube (Opcional)
         9000
```

### Servicios

| Servicio | Puerto | Tecnología | Propósito |
|----------|--------|-----------|----------|
| **db** | 5432 | PostgreSQL 15 | Base de datos principal |
| **ai** | 8001 | FastAPI + TensorFlow | Análisis de documentos médicos |
| **web** | 8000 | Django 4.2 | API REST principal |
| **frontend** | 5173 | Node 22 + Vite | Interfaz de usuario |
| **sonarqube** | 9000 | SonarQube (Opcional) | Análisis de código |

---

## Requisitos Previos

### Instalado en tu máquina:
- ✅ Docker Desktop (Windows/Mac) o Docker (Linux)
- ✅ Docker Compose (incluido en Docker Desktop)
- ✅ Git
- ✅ PowerShell o Bash (según tu SO)

### Versiones recomendadas:
```
Docker:        >= 24.0
Docker Compose >= 2.20
Python:        3.11 (en contenedores)
Node:          22 (en contenedores)
PostgreSQL:    15 (en contenedor)
```

---

## Instalación y Ejecución

### Opción 1: Script Automático (Recomendado)

**En PowerShell (Windows):**
```powershell
.\init-project.ps1
```

**En Bash (Linux/Mac):**
```bash
python init-project.py
```

Este script hace automáticamente:
- ✅ Limpia contenedores previos
- ✅ Compila imágenes Docker
- ✅ Levanta todos los servicios
- ✅ Ejecuta migraciones de BD
- ✅ Crea usuario de prueba

### Opción 2: Comandos Manuales

```bash
# 1. Limpiar estado previo (opcional)
docker-compose down -v --remove-orphans

# 2. Compilar imágenes
docker-compose build

# 3. Levantar servicios
docker-compose up -d

# 4. Verificar que todo está corriendo
docker-compose ps

# 5. Ver logs (opcional)
docker-compose logs -f web
```

---

## Servicios Disponibles

### 🌐 Frontend (Vite)
```
URL: http://localhost:5173
Tecnología: Node 22 + React + Vite
Estado: Automáticamente levantado
```

### 🔌 API Django
```
URL: http://localhost:8000
Endpoints principales:
  - POST   /api/register/          - Registrar usuario
  - POST   /api/login/            - Login
  - GET    /api/paciente/profile/ - Perfil de paciente
  - POST   /api/documents/upload/ - Subir documento
  - GET    /api/documents/        - Listar documentos
  - POST   /api/documents/{id}/analyze/ - Analizar con IA
  - GET    /admin/               - Panel administrativo
  - GET    /api/health/          - Health check

Documentación interactiva:
  - Swagger UI: http://localhost:8000/api/docs/swagger/
  - ReDoc: http://localhost:8000/api/docs/redoc/
```

### 🤖 AI Service
```
URL: http://localhost:8001
Tecnología: FastAPI + TensorFlow + MedSigLIP
Endpoints:
  - GET  /health - Health check
  - POST /analyze - Analizar imagen médica
```

### 📊 SonarQube (Opcional)
```
URL: http://localhost:9000
Tecnología: SonarQube + Elasticsearch embebido
Estado: DESHABILITADO por defecto (tarda 3-5 min en iniciar)

Para habilitar SonarQube:
docker-compose --profile sonarqube up -d sonarqube
```

### 🗄️ PostgreSQL
```
Host: db (dentro de Docker)
Host: localhost (desde máquina host)
Puerto: 5432
Base de datos: hmed_db
Usuario: admin
Contraseña: secret_pass
```

---

## Credenciales

### Usuario de Prueba
```
Usuario: testuser
Contraseña: changeme
Email: test@example.local
Tipo: Superusuario (acceso a admin panel)
```

### Base de Datos
```
Usuario BD: admin
Contraseña BD: secret_pass
Base de datos Django: hmed_db
Base de datos SonarQube: sonarqube
```

---

## Solución de Problemas

### ❌ Error: "database admin does not exist"

**Causa:** El healthcheck de PostgreSQL no encuentra la BD por defecto.

**Solución:** Ya está arreglado en la última actualización. Simplemente:
```bash
docker-compose down -v
docker-compose up --build
```

---

### ❌ Error: "web container unhealthy"

**Causa:** El healthcheck del web intenta acceder a `/api/health/` pero tarda más de lo esperado.

**Solución:** Aumenta los timeouts o espera 30-40 segundos a que Django se inicie completamente.

---

### ❌ Error: "Cannot connect to database"

**Causa:** El servicio `db` no está listo cuando `web` intenta conectarse.

**Verificación:**
```bash
# Ver estado del servicio db
docker-compose exec db pg_isready -U admin -d hmed_db

# Ver logs de db
docker-compose logs db
```

---

### ❌ SonarQube no inicia

**Causa:** SonarQube tarda 2-3 minutos en iniciar. El `start_period` necesit ser largo.

**Solución:** Para habilitar SonarQube:
```bash
# Con profile habilitado
docker-compose --profile sonarqube up -d sonarqube

# Esperar 3-4 minutos
# Verificar con:
docker-compose logs sonarqube
```

---

### ❌ ModuleNotFoundError en web

**Causa:** Falta una dependencia Python.

**Solución:**
1. Agregar el módulo a `backend/requirements.txt`
2. Recompilar: `docker-compose build web`
3. Reiniciar: `docker-compose up web`

---

### 🔄 Ejecutar Migraciones Manualmente

```bash
# Opción 1: Dentro del contenedor
docker-compose exec web python manage.py migrate

# Opción 2: Con el script helper
docker-compose exec web bash /app/manage-migrations.sh

# Opción 3: Ver estado de migraciones
docker-compose exec web python manage.py showmigrations
```

---

### 📝 Crear Superusuario Adicional

```bash
docker-compose exec web python manage.py createsuperuser
```

---

### 🧹 Limpiar Todo y Empezar de Cero

```bash
# Opción nuclear: elimina TODOS los volúmenes
docker-compose down -v --remove-orphans

# Opción conservadora: solo detiene servicios
docker-compose down

# Levantar nuevamente
docker-compose up --build
```

---

### 📋 Ver Logs de um Servicio

```bash
# Log en vivo (últimas líneas)
docker-compose logs -f web

# Log completo de un servicio
docker-compose logs db

# Últimas 100 líneas
docker-compose logs --tail=100 web

# Logs entre dos tiempos
docker-compose logs -f --timestamps web
```

---

## Variables de Entorno Configurables

Edita el archivo `.env` en la raíz del proyecto:

```env
# DEBUG MODE
DEBUG=False                    # True para desarrollo, False para producción

# DATABASE
DB_NAME=hmed_db               # Nombre de la BD
DB_USER=admin                 # Usuario de BD
DB_PASSWORD=secret_pass       # Contraseña de BD
DB_HOST=db                    # Host (db en Docker, localhost localmente)
DB_PORT=5432                  # Puerto PostgreSQL

# DJANGO SECRET
SECRET_KEY=django-insecure-*  # Cambiar en producción

# ALLOWED HOSTS
ALLOWED_HOSTS=localhost,127.0.0.1,web,frontend

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000

# SONARQUBE
# (No editar a menos que sea necesario)
```

---

## Comandos Útiles Rápidos

```bash
# Ver estado de todos los servicios
docker-compose ps

# Detener todos los servicios
docker-compose stop

# Reiniciar servicios específicos
docker-compose restart web

# Acceder a shell de Django
docker-compose exec web python manage.py shell

# Acceder a PostgreSQL
docker-compose exec db psql -U admin -d hmed_db

# Ver uso de recursos
docker stats

# Ejecutar comando personalizado
docker-compose exec web python manage.py <comando>
```

---

## Notas de Producción

Para desplegar en producción:

1. **Cambiar DEBUG a False** (ya está por defecto)
2. **Usar SECRET_KEY fuerte** en .env
3. **Cambiar credenciales de BD** 
4. **Usar HTTPS/SSL certificates**
5. **Configurar ALLOWED_HOSTS correctamente**
6. **Usar reverse proxy** (Nginx/Apache)
7. **Configurar backups automáticos** de la BD
8. **Monitorear logs y métricas**

---

## Soporte y Documentación Adicional

- 📖 Django: https://docs.djangoproject.com/
- 📖 FastAPI: https://fastapi.tiangolo.com/
- 📖 PostgreSQL: https://www.postgresql.org/docs/
- 📖 Docker: https://docs.docker.com/
- 📖 Vite: https://vitejs.dev/

---

**Última actualización:** 22 de marzo de 2026
**Versión:** 1.0
