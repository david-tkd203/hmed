# SonarQube - Análisis de Seguridad HMED

## Inicio Rápido

### Opción 1: Con validación (recomendado)
```powershell
# Valida que todo está configurado correctamente
.\validate-sonarqube.bat

# Ejecuta el análisis
.\start-security-analysis.bat
```

### Opción 2: Directo
```powershell
.\start-security-analysis.bat
```

### Opción 3: Si hay problemas descargando (alternativa)
```powershell
# Descarga manualmente sonar-scanner
.\download-sonar-scanner.bat

# Luego ejecuta el análisis
.\start-security-analysis.bat
```

---

## ¿Qué hace el script?

El script `start-security-analysis.bat` ejecuta automáticamente:

1. ✅ **Verifica Docker** - Asegura que Docker está corriendo
2. ✅ **Verifica SonarQube** - Espera a que SonarQube esté listo (hasta 10 intentos)
3. ✅ **Instala sonar-scanner** - Lo descarga e instala si falta
4. ✅ **Configura el proyecto** - Crea sonar-project.properties automáticamente
5. ✅ **Ejecuta análisis** - Analiza backend y frontend
6. ✅ **Abre resultados** - Muestra el reporte en http://localhost:9000/dashboard?id=HMED

---

## Requisitos Previos

### Docker Compose debe estar ejecutando
```powershell
# Inicia los servicios
docker-compose up -d

# Verifica el estado
docker-compose ps
```

Deberías ver:
- `sonarqube` - UP
- `db` - UP
- `web` - UP
- `frontend` - UP
- `ai` - UP

### Si SonarQube tarda en iniciar
Espera 30-60 segundos. Puedes verificar:
```powershell
docker-compose logs sonarqube | Select-Object -Last 10
```

---

## Acceso a SonarQube

**URL**: http://localhost:9000

**Credenciales**:
- Usuario: `admin`
- Contraseña: `admin`

**Dashboard del Proyecto**:
- http://localhost:9000/dashboard?id=HMED

---

## Si Hay Problemas

### Ver errores detallados
```powershell
# Ejecuta validation para detectar problemas
.\validate-sonarqube.bat

# Ve logs de Docker
docker-compose logs sonarqube
docker-compose logs db
```

### Guía de Troubleshooting
Lee el archivo `SONARQUBE_TROUBLESHOOTING.md` para soluciones a problemas comunes.

### Reiniciar todo
```powershell
# Detiene los contenedores
docker-compose down -v

# Reinicia
docker-compose up -d

# Espera 30 segundos y ejecuta nuevamente
.\start-security-analysis.bat
```

---

## Configuración Personalizada

Si necesitas cambiar la configuración, edita `sonar-project.properties`:

```properties
sonar.projectKey=HMED
sonar.projectName=HMED - Sistema de Historico Clinico
sonar.sources=.
sonar.inclusions=backend/**,frontend/**
sonar.exclusions=**/*test*,**/node_modules/**,**/.git/**
```

---

## Scripts Incluidos

| Script | Propósito |
|--------|-----------|
| `start-security-analysis.bat` | Ejecuta análisis completo de seguridad |
| `validate-sonarqube.bat` | Valida que todo está configurado correctamente |
| `sonar-project.properties` | Configuración del proyecto (generada automáticamente) |

---

## Tokens de Acceso (Avanzado)

Si prefieres usar token en lugar de contraseña:

1. Abre http://localhost:9000/account/security
2. Crea un nuevo token
3. Úsalo en el script:
   ```powershell
   $token = "tu_token_aqui"
   # El script lo utilizará automáticamente
   ```

---

## Qué se Analiza

- **Backend**: Python/Django (`backend/` directory)
- **Frontend**: JavaScript/React (`frontend/` directory)
- **Exclusiones**: `node_modules`, `migrations`, tests, `.git`

---

## Resultados

Los resultados incluyen:

- 🔐 **Vulnerabilidades de seguridad**
- 🐛 **Bugs identificados**
- 📊 **Code Smells**
- 📈 **Métricas de cobertura**
- 🎯 **Recomendaciones de mejora**

Accesibles en: http://localhost:9000/dashboard?id=HMED

---

## Soporte

Para problemas:
1. Revisa `SONARQUBE_TROUBLESHOOTING.md`
2. Consulta los logs: `docker-compose logs`
3. Valida config: `.\validate-sonarqube.bat`

