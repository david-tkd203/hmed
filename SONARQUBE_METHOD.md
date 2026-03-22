# SonarQube - Guía Actualizada

## ✅ Método Simplificado (Docker)

El script ahora usa **Docker directamente** - no necesita descargar sonar-scanner localmente.

### Ejecución
```powershell
.\start-security-analysis.bat
```

El script:
1. ✅ Verifica Docker
2. ✅ Verifica SonarQube está activo
3. ✅ Configura el proyecto automáticamente  
4. ✅ **Usa Docker para ejecutar sonar-scanner** (Java incluido)
5. ✅ Abre resultados en navegador

**Duración**: 2-5 minutos

---

## ¿Por qué Este Método?

| Aspecto | Local | Docker |
|--------|-------|--------|
| Java requerido | ✅ Sí, instalar | ❌ No |
| sonar-scanner | ✅ Descargar | ❌ No |
| Descarga errores | ⚠️ Frecuente | ✅ No |
| Configurar PATH | ✅ Necesario | ❌ No |
| Complejidad | 🔴 Alta | 🟢 Baja |
| Rapidez | ⏱️ Lento | ⚡ Rápido |
| Confiabilidad | ⚠️ Variable | ✅ Garantizada |

---

## Requisitos

### Docker debe estar corriendo
```powershell
docker ps
```

### SonarQube en Docker debe estar activo
```powershell
docker-compose ps
```

Deberías ver: `sonarqube ... UP`

---

## Acceso a Resultados

**URL**: http://localhost:9000/dashboard?id=HMED

**Credenciales**:
- Usuario: `admin`
- Contraseña: `admin`

---

## Si hay problemas

```powershell
# Verifica que Docker está corriendo
docker ps

# Verifica que SonarQube está activo
docker-compose logs sonarqube | Select-Object -Last 10

# Si SonarQube no está, inicia todo
docker-compose up -d

# Espera 30-60 segundos y ejecuta nuevamente
.\start-security-analysis.bat
```

---

## Configuración Automática

El script crea automáticamente `sonar-project.properties`:

```properties
sonar.projectKey=HMED
sonar.projectName=HMED - Sistema de Historico Clinico
sonar.sources=.
sonar.inclusions=backend/**,frontend/**
sonar.exclusions=**/*test*,**/node_modules/**,**/.git/**
```

---

## Métodos Alternativos (Avanzado)

### Opción 1: Usando run-sonar-analysis.sh (Bash)
```bash
bash run-sonar-analysis.sh
```

### Opción 2: Comando directo en PowerShell
```powershell
docker run --rm `
  --network="historicoclinico_hmed_network" `
  -v "$(pwd):/usr/src" `
  sonarsource/sonar-scanner-cli:latest `
  -Dsonar.projectKey=HMED `
  -Dsonar.sources=/usr/src/backend/registros,/usr/src/frontend/src `
  -Dsonar.host.url=http://sonarqube:9000 `
  -Dsonar.login=admin `
  -Dsonar.password=admin
```

### Opción 3: Descarga local sonar-scanner (si lo prefieres)
```powershell
.\download-sonar-scanner.bat
```

---

## ¿Qué se Analiza?

- ✅ Backend: `/backend/registros` (Django/Python)
- ✅ Frontend: `/frontend/src` (React/JavaScript)
- ⏭️ Exclusiones: test files, node_modules, migrations, .git

---

## Resultados Esperados

El análisis reporta:
- 🔐 Vulnerabilidades de seguridad
- 🐛 Bugs encontrados
- 📊 Code Smells (malas prácticas)
- 📈 Porcentaje de duplicación de código
- ⏰ Deuda técnica estimada

Disponible en: http://localhost:9000/dashboard?id=HMED

