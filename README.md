# 📋 HMED - Plataforma de Historial Clínico Global

> **Una solución integral para la gestión centralizada de registros clínicos con capacidades de análisis e integración IA**

---

## 📑 Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Arquitectura del Sistema](#🏗️-arquitectura-del-sistema---análisis-de-documentos-médicos)
- [Stack Tecnológico](#stack-tecnológico)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Puertos y Servicios](#puertos-y-servicios)
- [Configuración Inicial](#configuración-inicial)
- [Desarrollo Local](#desarrollo-local)
- [Autenticación JWT](#autenticación-jwt)
- [Rate Limiting](#rate-limiting)
- [Auditoría de Código con SonarQB](#auditoría-de-código-con-sonarqb)
- [Comandos de Base de Datos](#comandos-de-base-de-datos)
- [API REST](#api-rest)
- [Desarrollo Frontend](#desarrollo-frontend)
- [Solución de Problemas](#solución-de-problemas)

---

## 🎯 Descripción General

**HMED** es una plataforma web moderna diseñada para:

✅ **Centralizar** registros clínicos de múltiples proveedores de salud  
✅ **Consolidar** información médica en un historial único del paciente  
✅ **Facilitar** el análisis e integración de datos clínicos  
✅ **Preparar** la información para procesamiento con IA/ML  
✅ **Proporcionar** una interfaz intuitiva para pacientes y profesionales de salud  

**Casos de uso:**
- Pacientes pueden visualizar y gestionar su historial médico completo
- Médicos pueden acceder a información histórica completa durante consultas
- Profesionales de salud pueden generar análisis sobre patrones de medicamentos
- Integración futura con sistemas de IA para diagnósticos asistidos

---

## 🏗️ Arquitectura del Sistema - Análisis de Documentos Médicos

### Flujo de Análisis de Documentos

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                                                                                │
│  1️⃣  CARGAR DOCUMENTO                                                          │
│  ────────────────────────────────────────────────────────────────────────────  │
│  📁 Usuario sube PDF o Imagen                                                  │
│                                   ↓                                            │
│  2️⃣  EXTRAER TEXTO                                                             │
│  ────────────────────────────────────────────────────────────────────────────  │
│  📄 PDF          → PyPDF2 (extrae texto)                                       │
│  🖼️  Imagen       → pytesseract (OCR)                                          │
│                                   ↓                                            │
│  3️⃣  ANALIZAR DOCUMENTO                                                        │
│  ────────────────────────────────────────────────────────────────────────────  │
│  🔍 Identificar:                                                               │
│     • Tipo: Receta | Laboratorio | Radiografía | Oftalmología | Alergia       │
│     • Medicamentos: Paracetamol, Ibuprofeno, Amoxicilina, etc.                │
│     • Hallazgos: Presión alta, Glucosa elevada, Colesterol, Anemia, etc.      │
│     • Observaciones: Recomendaciones clínicas                                  │
│                                   ↓                                            │
│  4️⃣  GENERAR EMBEDDINGS (IA)                                                   │
│  ────────────────────────────────────────────────────────────────────────────  │
│  🤖 MedSigLIP → 448 dimensiones de embeddings                                  │
│  📊 Confidence score + Metadata                                                │
│                                   ↓                                            │
│  5️⃣  MOSTRAR RESULTADOS EN UI                                                  │
│  ────────────────────────────────────────────────────────────────────────────  │
│  💊 Tab "Extracción":                                                          │
│     ├─ Tipo de documento detectado                                             │
│     ├─ Medicamentos encontrados    💊                                          │
│     ├─ Hallazgos detectados        🔍                                          │
│     ├─ Observaciones clínicas      📝                                          │
│     └─ Texto extraído             📰                                           │
│                                                                                │
│  🌍 Soporte Multiidioma:                                                       │
│     🇪🇸 Español | 🇬🇧 English | 🇧🇷 Português                                  │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
```

### Componentes Clave

| Componente | Responsabilidad | Tecnología |
|-----------|-----------------|-----------|
| **Backend** | Extracción de información | Python Django |
| **PDF Extraction** | Obtener texto de PDFs | PyPDF2 |
| **OCR** | Convertir imágenes a texto | pytesseract + Tesseract |
| **Pattern Matching** | Identificar medicamentos y hallazgos | Regex + Pattern Lists |
| **Frontend** | Mostrar resultados en UI interactiva | React + i18n |
| **Database** | Almacenar documentos y análisis | PostgreSQL |

---

## 🛠️ Stack Tecnológico

### Backend
| Componente | Versión | Uso |
|-----------|---------|-----|
| **Python** | 3.11 | Runtime principal |
| **Django** | 5.2 | Framework web |
| **Django REST Framework** | Latest | API REST |
| **djangorestframework-simplejwt** | Latest | Autenticación JWT (Access + Refresh tokens) |
| **django-ratelimit** | Latest | Rate limiting por endpoint |
| **drf-spectacular** | Latest | OpenAPI 3.0 / Swagger / ReDoc |
| **django-cors-headers** | Latest | CORS configuration |
| **PostgreSQL** | 15 | Base de datos relacional |
| **psycopg2** | Latest | Driver PostgreSQL |
| **python-dotenv** | Latest | Gestión de variables de entorno |
| **Pillow** | Latest | Procesamiento de imágenes |

### Frontend
| Componente | Versión | Uso |
|-----------|---------|-----|
| **React** | 19.2.4 | Biblioteca UI |
| **Vite** | 8.0.0 | Build tool |
| **Axios** | 1.13.6 | Cliente HTTP |
| **react-bootstrap-icons** | 1.11.6 | Iconografía SVG |
| **ESLint** | 9.39.4 | Linting |

### Auditoría de Código
| Componente | Versión | Uso |
|-----------|---------|-----|
| **SonarQB Community** | Latest | Análisis estático, detección vulnerabilidades |
| **drf-spectacular** | Latest | Documentación automática (Swagger/ReDoc) |

### Infraestructura
| Componente | Versión | Uso |
|-----------|---------|-----|
| **Docker** | Latest | Containerización |
| **Docker Compose** | 3.8+ | Orquestación local (4 servicios) |

---

## 📂 Estructura del Proyecto

```
historico-clinico/
│
├── docker-compose.yml              # Orquestación de 4 servicios (DB + Web + Frontend + SonarQB)
├── sonar-project.properties        # Configuración análisis SonarQB
├── run-sonar-analysis.sh           # Script automatizado para auditoría código
├── SONARQB_SETUP.md                # Guía de uso SonarQB
├── API_DOCUMENTATION.md            # Documentación de endpoints + rate limiting
├── README.md                       # Este archivo
├── DEPLOYMENT_GUIDE.md             # Guía de despliegue a producción
├── package.json                    # Root package (para scripts globales)
│
├── backend/                        # Proyecto Django
│   ├── Dockerfile                  # Imagen Docker para Django (python:3.11-slim)
│   ├── requirements.txt            # Dependencias Python
│   ├── manage.py                   # CLI de Django
│   │
│   ├── Hmed/                       # Configuración principal del proyecto
│   │   ├── __init__.py
│   │   ├── settings.py             # Django settings + JWT + CORS + DRF
│   │   ├── urls.py                 # Rutas (API + Swagger/ReDoc/Schema)
│   │   ├── asgi.py                 # Configuración ASGI
│   │   └── wsgi.py                 # Configuración WSGI
│   │
│   └── registros/                  # Aplicación de registros clínicos
│       ├── models.py               # Modelos de datos
│       ├── views.py                # ViewSets + rate limiting + JWT
│       ├── rate_limiters.py        # Decorador custom_ratelimit (NEW)
│       ├── rate_limit_config.py    # Configuración de límites (NEW)
│       ├── admin.py                # Panel administrador
│       ├── apps.py
│       ├── tests.py
│       └── migrations/             # Migraciones de BD
│           └── 0001_initial.py
│
├── frontend/                       # Proyecto React + Vite
│   ├── Dockerfile                  # Imagen Docker (node:22-alpine)
│   ├── .env.local                  # Variables de entorno (NEW)
│   ├── vite.config.js              # Configuración de Vite
│   ├── eslint.config.js            # Configuración de ESLint
│   ├── package.json                # Dependencias (React, Axios, Bootstrap Icons)
│   ├── index.html                  # HTML de entrada
│   │
│   ├── public/                     # Assets estáticos
│   │   └── ...
│   │
│   └── src/                        # Código fuente
│       ├── main.jsx                # Punto de entrada React
│       ├── App.jsx                 # Componente raíz con autenticación
│       ├── Login.jsx               # Login con JWT + rate limit (NEW)
│       ├── Onboarding.jsx          # Perfil inicial del usuario (NEW)
│       ├── RateLimitError.jsx      # Componente error 429 con countdown (NEW)
│       ├── Dashboard.jsx           # Panel principal (NEW)
│       ├── App.css
│       ├── index.css
│       ├── RateLimitError.css      # Estilos error rate limit (NEW)
│       └── assets/
│           └── ...
```

---

## ⚙️ Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

### Obligatorio
- **Docker** (v20.10+) - [Descargar](https://www.docker.com/)
- **Docker Compose** (v2.0+) - Generalmente viene con Docker Desktop
- **Git** - [Descargar](https://git-scm.com/)

### Opcional (para desarrollo sin Docker)
- **Python** 3.11+ - [Descargar](https://www.python.org/)
- **Node.js** 18+ con npm - [Descargar](https://nodejs.org/)
- **PostgreSQL** 15+ (si no usas Docker)

### Verificar instalación
```bash
# Verificar Docker
docker --version
docker-compose --version

# Verificar Git
git --version

# Verificar Node.js (opcional)
node --version
npm --version
```

---

## 🌐 Puertos y Servicios

La aplicación levanta **4 servicios** en Docker. Estos son los puertos utilizados:

| Servicio | Puerto | URL | Usuario | Contraseña | Descripción |
|----------|--------|-----|---------|------------|-------------|
| **PostgreSQL** | 5432 | localhost:5432 | admin | secret_pass | Base de datos relacional |
| **Django API** | 8000 | http://localhost:8000 | N/A | N/A | API REST + Admin panel |
| **Swagger/ReDoc** | 8000 | http://localhost:8000/api/docs/swagger/ | N/A | N/A | Documentación interactiva |
| **React Frontend** | 5173 | http://localhost:5173 | N/A | N/A | Interfaz de usuario |
| **SonarQB** | 9000 | http://localhost:9000 | admin* | (ver env vars) | Auditoría código & vulnerabilidades |

### Verificar que todos los servicios están corriendo

```bash
# Ver estado de todos los contenedores
docker-compose ps

# Salida esperada:
# NAME                   SERVICE      STATUS      PORTS
# historicoclinico-db-1       db           Up 2m       0.0.0.0:5432->5432/tcp
# historicoclinico-web-1      web          Up 2m       0.0.0.0:8000->8000/tcp
# historicoclinico-frontend-1 frontend     Up 2m       0.0.0.0:5173->5173/tcp
# sonarqube                    sonarqube    Up 2m       0.0.0.0:9000->9000/tcp
```

---

## 🚀 Configuración Inicial

### 1️⃣ Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/historico-clinico.git
cd historico-clinico
```

### 2️⃣ Configurar variables de entorno

#### Backend (.env)
Crea un archivo `.env` en la raíz del proyecto:

```bash
# Crear archivo .env en la raíz
cat > .env << EOF
# Django Settings
DEBUG=True
SECRET_KEY=tu-clave-secreta-segura-aqui-cambiar-en-produccion
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0

# Database
DATABASE_URL=postgres://admin:secret_pass@db:5432/hmed_db
POSTGRES_DB=hmed_db
POSTGRES_USER=admin
POSTGRES_PASSWORD=secret_pass

# CORS & Frontend
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
EOF
```

⚠️ **IMPORTANTE**: En producción, cambiar `DEBUG=False` y usar claves seguras.

### 3️⃣ Levantar la aplicación con Docker Compose (4 servicios)

```bash
# Construir imágenes y crear contenedores (primera vez)
docker-compose up -d --build

# Ver logs en tiempo real
docker-compose logs -f

# Si ya existen los contenedores, simplemente levantarlos
docker-compose up -d

# Verificar que los 4 servicios están corriendo
docker-compose ps
```

**Salida esperada:**
```
NAME                    COMMAND             SERVICE      STATUS      PORTS
historicoclinico-db-1       "docker-entrypoint.s…"   db           Up 2m       0.0.0.0:5432->5432/tcp
historicoclinico-web-1      "python manage.py ru…"   web          Up 2m       0.0.0.0:8000->8000/tcp
historicoclinico-frontend-1 "docker-entrypoint.s…"   frontend     Up 2m       0.0.0.0:5173->5173/tcp
sonarqube                    "/opt/sonarqube/dock…"   sonarqube    Up 2m       0.0.0.0:9000->9000/tcp
```

### 4️⃣ Aplicar migraciones de base de datos

```bash
# Crear las tablas en PostgreSQL
docker-compose exec web python manage.py migrate

# Crear el usuario administrador
docker-compose exec web python manage.py createsuperuser
# Sigue las instrucciones interactivas
```

### 5️⃣ Crear usuario de prueba

```bash
# Crear usuario de prueba (demo/123456)
docker-compose exec web python manage.py create_test_user
```

### 6️⃣ Acceder a los servicios

✅ **Frontend**: [http://localhost:5173](http://localhost:5173)  
   - Usuario: `demo` | Contraseña: `123456`

✅ **API Documentation**: [http://localhost:8000/api/docs/swagger/](http://localhost:8000/api/docs/swagger/)  
   - Interfaz interactiva para probar endpoints

✅ **ReDoc Documentation**: [http://localhost:8000/api/docs/redoc/](http://localhost:8000/api/docs/redoc/)  
   - Documentación legible en ReDoc

✅ **Django Admin**: [http://localhost:8000/admin](http://localhost:8000/admin)  
   - Usuario: `admin` | (Crear con `createsuperuser`)

✅ **SonarQB Code Analysis**: [http://localhost:9000](http://localhost:9000)  
   - Usuario: `admin` | Contraseña: `admin`

✅ **Base de datos**: `localhost:5432`  
   - Usuario: `admin` | Contraseña: `secret_pass`

---

## 💻 Desarrollo Local

### Opción A: Desarrollo con Docker (Recomendado)

#### 1. Backend
```bash
# Los cambios en backend/ se sincronizan automáticamente
# Los logs del servidor están disponibles con:
docker-compose logs -f web

# Para parar Django y reiniciar:
docker-compose restart web
```

#### 2. Frontend
```bash
# En una nueva terminal, navega al directorio frontend
cd frontend

# Instala dependencias
npm install

# Inicia el servidor de desarrollo (Vite)
npm run dev

# Abre http://localhost:5173
```

### Opción B: Desarrollo local sin Docker

#### Backend
```bash
cd backend

# Crear entorno virtual
python -m venv venv

# Activar entorno (Windows)
venv\Scripts\activate

# Activar entorno (Mac/Linux)
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar migraciones
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser

# Iniciar servidor
python manage.py runserver
```

#### Frontend
```bash
cd frontend

# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm run dev
```

---

## � Autenticación JWT

La API usa **SimplJWT** con tokens de acceso (1 hora) y refresh (7 días).

### Obtener tokens
```bash
# Login (devuelve access_token + refresh_token)
curl -X POST http://localhost:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "demo", "password": "123456"}'

# Respuesta:
# {
#   "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "user": {"id": 1, "username": "demo", ...}
# }
```

### Usar token en requests
```bash
# Incluir en header Authorization
curl -H "Authorization: Bearer <access_token>" \
  http://localhost:8000/api/paciente/profile/
```

### Refrescar token expirado
```bash
# Cuando el access_token expire (1 hora), usar refresh_token
curl -X POST http://localhost:8000/api/token/refresh/ \
  -H "Content-Type: application/json" \
  -d '{"refresh": "<refresh_token>"}'

# Devuelve nuevo access_token
```

---

## ⏱️ Rate Limiting

La API implementa rate limiting automático por endpoint para prevenir abuso:

| Endpoint | Límite | Ventana | Identificador | Respuesta |
|----------|--------|---------|---------------|----------|
| `/api/login/` | 5 | 1 hora | IP | 429 + Retry-After |
| `/api/register/` | 3 | 1 hora | IP | 429 + Retry-After |
| `/api/token/refresh/` | 10 | 1 hora | IP | 429 + Retry-After |
| `/api/file/validate/` | 20 | 1 hora | Usuario | 429 + Retry-After |
| `/api/registro/upload/` | 20 | 1 hora | Usuario | 429 + Retry-After |
| `/api/paciente/profile/` | 30 | 1 hora | Usuario | 429 + Retry-After |

### Manejar error 429 (Too Many Requests)

```javascript
// Frontend - Axios interceptor
axios.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 429) {
      const retryAfter = error.response.headers['retry-after'];
      console.log(`Rate limitado. Reintentar en ${retryAfter} segundos`);
      // Mostrar componente RateLimitError con countdown
    }
    return Promise.reject(error);
  }
);
```

### Ejemplo respuesta 429
```json
{
  "detail": "Demasiados intentos de inicio de sesión. Límite: 5 intentos/hora por IP.",
  "retry_after": 3600
}

Headers:
Retry-After: 3600
```

---

## 🔍 Auditoría de Código con SonarQB

### ⚡ Inicio Rápido (RECOMENDADO - Windows)

```powershell
cd "c:\Users\david\OneDrive\Escritorio\historico clinico"
.\start-security-analysis.bat
```

Este script automáticamente:
1. ✅ Descarga sonar-scanner (si no está instalado)
2. ✅ Verifica Java
3. ✅ Verifica conexión a SonarQube
4. ✅ Ejecuta el análisis completo
5. ✅ Abre resultados en navegador

### Pasos Previos (Primera vez)

```powershell
# 1. Iniciar SonarQube
docker-compose up -d sonarqube db

# 2. Esperar 2-3 minutos hasta que SonarQube esté listo
# 3. Verificar: http://localhost:9000

# 4. Ejecutar análisis
.\start-security-analysis.bat
```

### Análisis Manual (Sin Script)

```bash
# Si prefieres ejecutar directo
sonar-scanner `
  -Dsonar.projectBaseDir=. `
  -Dsonar.host.url=http://localhost:9000 `
  -Dsonar.login=admin `
  -Dsonar.password=20394117Tkd+
```

### Ver Resultados

1. Accede a **http://localhost:9000**
2. Inicia sesión: `admin` / `admin`
3. Click en proyecto **"hmed-full"**
4. Análisis disponibles:

   📊 **Overview** - Resumen general  
   🐛 **Issues** - Bugs por severidad  
   🔒 **Security** - Vulnerabilidades (SQL injection, XSS, etc.)  
   ⚠️ **Code Smells** - Malas prácticas y complejidad  
   📈 **Duplications** - Código duplicado  
   🚀 **Deuda Técnica** - Horas estimadas para arreglarlo  

### Archivos de Configuración

- **sonar-project.properties** - Configuración del análisis
- **start-security-analysis.bat** - Script automático (Windows)
- **install-and-analyze.ps1** - Instalador y ejecutor (PowerShell)
- **run-sonar-analysis.bat/sh** - Scripts básicos

Para más detalles: [SONARQUBE_GUIDE.md](SONARQUBE_GUIDE.md)

---

## �🗄️ Comandos de Base de Datos

### Migraciones

```bash
# Crear nuevas migraciones basadas en cambios de modelos
docker-compose exec web python manage.py makemigrations

# Aplicar migraciones pendientes
docker-compose exec web python manage.py migrate

# Ver estado de migraciones
docker-compose exec web python manage.py showmigrations
```

### Datos

```bash
# Crear superusuario (administrador)
docker-compose exec web python manage.py createsuperuser

# Cargar datos de fixture
docker-compose exec web python manage.py loaddata nombre-fixture

# Exportar datos a fixture
docker-compose exec web python manage.py dumpdata registros > backup.json
```

### Limpieza

```bash
# Limpiar la base de datos (CUIDADO: elimina datos)
docker-compose exec web python manage.py flush

# Crear usuario de prueba
docker-compose exec web python manage.py create_test_user

# Eliminar todos los contenedores y volúmenes (CUIDADO: pérdida TOTAL de datos)
docker-compose down -v

# Limpiar solo datos de SonarQB
docker volume rm historicoclinico_sonarqube_data
docker-compose up -d sonarqube
```

### Base de Datos PostgreSQL

```bash
# Conectarse directamente a PostgreSQL
docker-compose exec db psql -U admin -d hmed_db

# Comandos útiles dentro de psql:
\dt                 # Listar todas las tablas
\d tabla_nombre     # Ver estructura de tabla
SELECT * FROM tabla_nombre;  # Ver datos
\du                 # Listar usuarios
\q                  # Salir
```

---

## 🔌 API REST

### Documentación interactiva

- **Swagger UI**: [http://localhost:8000/api/docs/swagger/](http://localhost:8000/api/docs/swagger/)
- **ReDoc**: [http://localhost:8000/api/docs/redoc/](http://localhost:8000/api/docs/redoc/)
- **OpenAPI Schema**: [http://localhost:8000/api/schema/](http://localhost:8000/api/schema/)

### Autenticación

La API requiere token JWT. Ver sección [Autenticación JWT](#autenticación-jwt).

### Endpoints Principales

#### Autenticación
```
POST   /api/login/                  # Obtener access/refresh tokens
POST   /api/register/               # Registrar nuevo usuario
POST   /api/token/refresh/          # Refrescar access token expirado
```

#### Perfil de Paciente
```
GET    /api/paciente/profile/       # Obtener perfil del usuario
PATCH  /api/paciente/profile/       # Actualizar datos opcionales (teléfono, dirección, etc)
```

#### Validación de Archivos
```
POST   /api/file/validate/          # Validar archivo antes de subir
POST   /api/registro/upload/        # Subir registro clínico con archivo
```

### Ejemplo: Login y obtener token

```bash
# Login
curl -X POST http://localhost:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "demo", "password": "123456"}'

# Respuesta:
# {
#   "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "user": {"id": 1, "username": "demo"}
# }

# Usar el token
TOKEN="<access_token_aqui>"
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/paciente/profile/
```

### Ejemplo: Actualizar perfil

```bash
curl -X PATCH http://localhost:8000/api/paciente/profile/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "telefono": "+1-555-0123",
    "direccion": "Calle Principal 123",
    "ciudad": "New York",
    "pais": "USA",
    "alergias": "Penicilina",
    "enfermedades_cronicas": "Diabetes tipo 2"
  }'
```

Ver [API_DOCUMENTATION.md](API_DOCUMENTATION.md) para documentación completa con ejemplos CURL.

---

## 🎨 Desarrollo Frontend

### Estructura base
```javascript
// src/App.jsx - Componente principal
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Heart } from 'lucide-react';

function App() {
  const [registros, setRegistros] = useState([]);

  useEffect(() => {
    // Fetch registros del API
    axios.get('http://localhost:8000/api/registros/')
      .then(res => setRegistros(res.data))
      .catch(err => console.error(err));
  }, []);

  return (
    <div className="App">
      <h1><Heart /> HMED - Historial Clínico</h1>
      {/* Contenido aquí */}
    </div>
  );
}

export default App;
```

### Comandos útiles
```bash
cd frontend

# Instalar nuevas dependencias
npm install nombre-paquete

# Desarrollo con hot reload
npm run dev

# Compilar para producción
npm build

# Previsualizar build
npm run preview

# Linting
npm run lint

# Linting con correcciones automáticas
npm run lint -- --fix
```

### Variables de entorno Frontend (.env.local)
```
VITE_API_URL=http://localhost:8000
VITE_APP_NAME=HMED
```

---

## 🐛 Solución de Problemas

### El puerto 8000 ya está en uso
```bash
# Encontrar qué proceso usa el puerto
netstat -ano | findstr :8000  # Windows
lsof -i :8000                # Mac/Linux

# Cambiar puerto en docker-compose.yml
# Modificar: "8000:8000" a "8001:8000"
```

### PostgreSQL: "connection refused"
```bash
# Verificar que el contenedor de BD está corriendo
docker-compose ps

# Reiniciar la base de datos
docker-compose restart db

# Ver logs de BD
docker-compose logs db
```

### Node modules corrupto
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### Migración falla
```bash
# Ver el error completo
docker-compose exec web python manage.py migrate --verbosity 3

# Hacer rollback de una migración
docker-compose exec web python manage.py migrate registros 0001
```

### El frontend no se conecta al backend
- Verificar que `CORS_ALLOWED_ORIGINS` en `.env` incluye el puerto del frontend
- Verificar que `VITE_API_URL` apunta al backend correcto
- Ver Console del navegador para errores CORS

```bash
# Verificar CORS en backend
docker-compose exec web python manage.py shell
>>> from django.conf import settings
>>> print(settings.CORS_ALLOWED_ORIGINS)
```
