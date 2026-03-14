# 📋 HMED - Plataforma de Historial Clínico Global

> **Una solución integral para la gestión centralizada de registros clínicos con capacidades de análisis e integración IA**

---

## 📑 Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Stack Tecnológico](#stack-tecnológico)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Configuración Inicial](#configuración-inicial)
- [Desarrollo Local](#desarrollo-local)
- [Comandos de Base de Datos](#comandos-de-base-de-datos)
- [API REST](#api-rest)
- [Desarrollo Frontend](#desarrollo-frontend)
- [Solución de Problemas](#solución-de-problemas)
- [Contribución](#contribución)

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

## 🛠️ Stack Tecnológico

### Backend
| Componente | Versión | Uso |
|-----------|---------|-----|
| **Python** | 3.11 | Runtime principal |
| **Django** | 5.2 | Framework web |
| **Django REST Framework** | Latest | API REST |
| **PostgreSQL** | 15 | Base de datos (producción) |
| **psycopg2** | Latest | Driver PostgreSQL |
| **python-dotenv** | Latest | Gestión de variables de entorno |
| **Pillow** | Latest | Procesamiento de imágenes |

### Frontend
| Componente | Versión | Uso |
|-----------|---------|-----|
| **React** | 19.2.4 | Biblioteca UI |
| **Vite** | 8.0.0 | Build tool |
| **Axios** | 1.13.6 | Cliente HTTP |
| **Lucide React** | 0.577.0 | Iconografía |
| **ESLint** | 9.39.4 | Linting |

### Infraestructura
| Componente | Versión | Uso |
|-----------|---------|-----|
| **Docker** | Latest | Containerización |
| **Docker Compose** | 3.8 | Orquestación local |

---

## 📂 Estructura del Proyecto

```
historico-clinico/
│
├── docker-compose.yml              # Orquestación de servicios (DB + Web)
├── README.md                        # Este archivo
├── DEPLOYMENT_GUIDE.md              # Guía de despliegue a producción
├── package.json                     # Root package (para scripts globales)
│
├── backend/                         # Proyecto Django
│   ├── Dockerfile                   # Imagen Docker para Django
│   ├── requirements.txt             # Dependencias Python
│   ├── manage.py                    # CLI de Django
│   ├── db.sqlite3                   # Base de datos SQLite (desarrollo)
│   │
│   ├── Hmed/                        # Configuración principal del proyecto
│   │   ├── __init__.py
│   │   ├── settings.py              # Configuración de Django
│   │   ├── urls.py                  # Rutas principales
│   │   ├── asgi.py                  # Configuración ASGI
│   │   └── wsgi.py                  # Configuración WSGI
│   │
│   └── registros/                   # Aplicación de registros clínicos
│       ├── models.py                # Modelos (RegistroClinico, Medicamento)
│       ├── views.py                 # Vistas/ViewSets
│       ├── admin.py                 # Configuración de admin
│       ├── apps.py
│       ├── tests.py
│       │
│       └── migrations/              # Migraciones de BD
│           └── 0001_initial.py
│
└── frontend/                        # Proyecto React + Vite
    ├── vite.config.js               # Configuración de Vite
    ├── eslint.config.js             # Configuración de ESLint
    ├── package.json                 # Dependencias (React, Axios, etc)
    ├── index.html                   # HTML de entrada
    │
    ├── public/                      # Assets estáticos
    │   └── ...
    │
    └── src/                         # Código fuente
        ├── main.jsx                 # Punto de entrada React
        ├── App.jsx                  # Componente raíz
        ├── App.css
        ├── index.css
        └── assets/
            └── ...
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

### 3️⃣ Levantar la aplicación con Docker Compose

```bash
# Descargar imágenes y crear contenedores
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Verificar que los servicios están corriendo
docker-compose ps
```

**Salida esperada:**
```
NAME              COMMAND                  SERVICE   STATUS      PORTS
historico-clinico-db-1    "docker-entrypoint.s…"   db        Up 2 minutes   5432/tcp
historico-clinico-web-1   "python manage.py ru…"   web       Up 2 minutes   0.0.0.0:8000->8000/tcp
```

### 4️⃣ Aplicar migraciones de base de datos

```bash
# Crear las tablas en PostgreSQL
docker-compose exec web python manage.py migrate

# Crear el usuario administrador
docker-compose exec web python manage.py createsuperuser
# Sigue las instrucciones interactivas
```

### 5️⃣ Verificar que todo funciona

- **API Backend**: Abre [http://localhost:8000](http://localhost:8000)
- **Admin Panel**: Abre [http://localhost:8000/admin](http://localhost:8000/admin)
- **Base de datos**: El contenedor PostgreSQL está disponible en `localhost:5432`

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

## 🗄️ Comandos de Base de Datos

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

# Eliminar todos los contenedores y volúmenes (CUIDADO: pérdida total de datos)
docker-compose down -v
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

### Autenticación
La API requiere token JWT para la mayoría de endpoints.

```bash
# Obtener token
curl -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "user", "password": "pass"}'

# Usar token en requests
curl -H "Authorization: Bearer tu-token" http://localhost:8000/api/registros/
```

### Endpoints Principales

#### Registros Clínicos
```
GET    /api/registros/              # Listar todos los registros
POST   /api/registros/              # Crear nuevo registro
GET    /api/registros/{id}/         # Obtener un registro
PUT    /api/registros/{id}/         # Actualizar registro
DELETE /api/registros/{id}/         # Eliminar registro
```

#### Medicamentos
```
GET    /api/medicamentos/           # Listar medicamentos
POST   /api/medicamentos/           # Crear medicamento
GET    /api/medicamentos/{id}/      # Obtener medicamento
PUT    /api/medicamentos/{id}/      # Actualizar medicamento
DELETE /api/medicamentos/{id}/      # Eliminar medicamento
```

### Ejemplo de Request
```bash
# Crear un nuevo registro clínico
curl -X POST http://localhost:8000/api/registros/ \
  -H "Authorization: Bearer tu-token" \
  -H "Content-Type: application/json" \
  -d '{
    "especialidad": "Cardiología",
    "clinica": "Clínica Central",
    "fecha_consulta": "2024-03-14",
    "diagnostico": "Hipertensión controlada"
  }'
```

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
