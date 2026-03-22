# 🚀 Guía de Inicio - Histórico Clínico HMED + SonarQube

## Requisitos Previos
- Docker Desktop instalado y ejecutándose
- Docker Compose v2.0+
- Puerto 5432, 8000, 5173, 8001, 9000 disponibles

## Inicio Rápido

### 1. Eliminar servicios previos (si existen)
```powershell
cd "c:\Users\david\OneDrive\Escritorio\historico clinico"
docker-compose down -v --remove-orphans
```

### 2. Iniciar todos los servicios
```powershell
docker-compose up --build
```

El proceso tardará 2-3 minutos en la primera ejecución.

### 3. Esperar a que todos los servicios estén listos

Verás algo como:
```
web_1          | Starting development server with code reloading...
ai_1           | AI service ready at http://localhost:8001
frontend_1     | VITE v4.x.x ready in 1234 ms
sonarqube_1    | SonarQube is up
```

## 🌐 Acceso a los Servicios

| Servicio | URL | Usuario | Contraseña | Puerto |
|----------|-----|---------|-----------|--------|
| **Frontend** | http://localhost:5173 | - | - | 5173 |
| **Backend API** | http://localhost:8000 | - | - | 8000 |
| **SonarQube** | http://localhost:9000 | admin | admin | 9000 |
| **BD PostgreSQL** | localhost | admin | secret_pass | 5432 |
| **AI Service** | http://localhost:8001 | - | - | 8001 |

## 🔑 Primeros Pasos con SonarQube

### Primera vez:
1. Abre http://localhost:9000
2. Login:
   - Usuario: `admin`
   - Contraseña: `admin`
3. Se te pedirá cambiar la contraseña
4. Sigue el asistente de setup

### Proyectos de Ejemplo:
```powershell
# Backend (Python/Django)
cd backend
sonar-scanner -Dsonar.projectKey=hmed-backend -Dsonar.sources=. -Dsonar.hosts.url=http://localhost:9000 -Dsonar.login=admin -Dsonar.password=admin

# Frontend (JavaScript/React)
cd frontend
npm install -g sonar-scanner
sonar-scanner -Dsonar.projectKey=hmed-frontend -Dsonar.sources=src -Dsonar.hosts.url=http://localhost:9000 -Dsonar.login=admin -Dsonar.password=admin
```

## 🔧 Comandos Útiles

```powershell
# Ver estado de contenedores
docker ps

# Ver logs de un servicio
docker-compose logs -f web        # Backend
docker-compose logs -f frontend   # Frontend
docker-compose logs -f sonarqube  # SonarQube
docker-compose logs -f db         # Database

# Detener servicios
docker-compose down

# Remover todo incluyendo volúmenes
docker-compose down -v --remove-orphans

# Reiniciar un servicio
docker-compose restart sonarqube
```

## 📊 Verificar Servicios

```powershell
# Backend API
curl http://localhost:8000/api/

# SonarQube API
curl http://localhost:9000/api/system/health

# Database
psql -h localhost -U admin -d hmed_db
```

## 🐛 Solución de Problemas

### SonarQube no inicia
```powershell
# Reiniciar SonarQube
docker-compose restart sonarqube
docker-compose logs -f sonarqube
```

### Puerto ocupado
```powershell
# Encontrar qué proceso usa el puerto
netstat -ano | findstr :9000

# Cambiar puerto en docker-compose.yml si es necesario
# "9000:9000" → "9001:9000" (acceso por 9001)
```

### Base de datos no se conecta
```powershell
# Reiniciar todo con volúmenes limpios
docker-compose down -v
docker-compose up --build
```

### Frontend no se ve
```powershell
# Esperar a que npm termine de compilar (puede tardar)
docker-compose logs -f frontend

# Si está stuck, reiniciar
docker-compose restart frontend
```

## 🔒 Seguridad

⚠️ **IMPORTANTE**: Estas son credenciales por defecto para desarrollo. NUNCA usar en producción:

- **SonarQube**: 
  - Usuarios: `admin` / `admin`
  - Base datos: `sonar_user` / `sonar_password`
  
- **PostgreSQL**:
  - Admin: `admin` / `secret_pass`

Para producción, cambiar TODAS las contraseñas en `docker-compose.yml` e `init-db.sql`.

## 📝 Notas

- El diseño es **responsive** y soporta **tema oscuro/claro**
- Extracción **automática** de información médica (médico, medicamentos, diagnóstico)
- Integración con **SonarQube** para auditoría de código
- Base de datos **PostgreSQL** con persistencia de datos

---

**Última actualización**: 21 de marzo de 2026
