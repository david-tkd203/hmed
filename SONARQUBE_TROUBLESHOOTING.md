# SonarQube - Guía de Solución de Problemas

## Ejecución Rápida

```powershell
.\start-security-analysis.bat
```

Este comando ejecuta automáticamente:
1. Verifica Docker
2. Verifica SonarQube en http://localhost:9000
3. Instala sonar-scanner (si falta)
4. Genera configuración de proyecto
5. Ejecuta análisis completo
6. Abre resultados en navegador

---

## Problemas Comunes y Soluciones

### Error: Docker no está corriendo
**Síntoma**: `[FAIL] Docker no esta disponible`

**Solución**:
```powershell
# Inicia Docker Desktop (Windows)
# O usa WSL2:
docker ps
```

---

### Error: No se puede conectar a SonarQube
**Síntoma**: `[FAIL] No se puede conectar a SonarQube en http://localhost:9000`

**Solución**:
```powershell
# Verifica que los contenedores están corriendo
docker-compose ps

# Si no están activos, inicia el proyecto
docker-compose up -d

# Espera 30-60 segundos a que SonarQube inicie
# Verifica el estado
docker-compose logs sonarqube | Select-Object -Last 20
```

---

### Error: No se puede descargar sonar-scanner
**Síntoma**: `[FAIL] No se pudo descargar de ninguna fuente`

**Causa**: El servidor puede rechazar las solicitudes de PowerShell por razones de seguridad

**Soluciones**:

**Opción 1: Descargar manualmente (RECOMENDADO)**
1. Ve a: https://www.sonarsource.com/products/sonarqube/downloads/
2. Descarga version 4.8.0.3345 para Windows (x86_64)
3. Extrae el ZIP en: `C:\sonar-scanner`
4. Estructura esperada:
   ```
   C:\sonar-scanner\
     ├── bin\
     │   ├── sonar-scanner.bat
     │   └── sonar-scanner
     ├── lib\
     └── conf\
   ```
5. Ejecuta nuevamente: `.\start-security-analysis.bat`

**Opción 2: Usar Git Bash o curl (si está disponible)**
```bash
curl -L -o sonar-scanner.zip "https://github.com/SonarSource/sonar-scanner-cli/releases/download/4.8.0.3345/sonar-scanner-cli-4.8.0.3345-windows-x86_64.zip"
Expand-Archive -Path sonar-scanner.zip -DestinationPath C:\sonar-scanner\
```

**Opción 3: Usar PowerShell con User-Agent
```powershell
$url = "https://github.com/SonarSource/sonar-scanner-cli/releases/download/4.8.0.3345/sonar-scanner-cli-4.8.0.3345-windows-x86_64.zip"
$headers = @{"User-Agent" = "Mozilla/5.0"}
Invoke-WebRequest -Uri $url -OutFile sonar-scanner.zip -Headers $headers
Expand-Archive -Path sonar-scanner.zip -DestinationPath C:\sonar-scanner\
```

**Opción 4: Reinstalar completamente
```powershell
# Elimina la instalación
Remove-Item C:\sonar-scanner -Recurse -Force -ErrorAction SilentlyContinue

# Ejecuta el script nuevamente
.\start-security-analysis.bat
```

---

### Error: El análisis falla pero SonarQube está disponible
**Síntoma**: Error en la ejecución de sonar-scanner

**Soluciones**:
1. Asegúrate de estar en la carpeta correcta del proyecto:
```powershell
cd "c:\Users\david\OneDrive\Escritorio\historico clinico"
```

2. Verifica que el archivo sonar-project.properties existe:
```powershell
Get-Item sonar-project.properties
```

3. Ejecuta con más verbosidad:
```powershell
C:\sonar-scanner\bin\sonar-scanner.bat -X
```

---

## Acceso a SonarQube

**URL**: http://localhost:9000

**Credenciales por defecto**:
- Usuario: `admin`
- Contraseña: `admin`

**Dashboard del proyecto**: http://localhost:9000/dashboard?id=HMED

---

## Pasos Manuales Alternativos

Si el script no funciona, ejecuta manualmente:

### 1. Instalar sonar-scanner
```powershell
# Descarga
$url = "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.3345-windows-x86_64.zip"
$output = "$env:TEMP\sonar-scanner.zip"
Invoke-WebRequest -Uri $url -OutFile $output

# Extrae
Expand-Archive -Path $output -DestinationPath "C:\sonar-scanner-extracted"
Copy-Item "C:\sonar-scanner-extracted\sonar-scanner-4.8.0.3345-windows\*" -Destination "C:\sonar-scanner" -Recurse

# Agrega a PATH
$env:PATH += ";C:\sonar-scanner\bin"
```

### 2. Crear archivo de configuración
Archivo: `sonar-project.properties`
```properties
sonar.projectKey=HMED
sonar.projectName=HMED - Sistema de Historico Clinico
sonar.projectVersion=1.0
sonar.sourceEncoding=UTF-8

sonar.sources=.
sonar.inclusions=backend/**,frontend/**
sonar.exclusions=**/*test*,**/node_modules/**,**/.git/**,**/migrations/**

sonar.host.url=http://localhost:9000
```

### 3. Ejecutar análisis
```powershell
cd "c:\Users\david\OneDrive\Escritorio\historico clinico"

# Con credenciales
sonar-scanner `
  -Dsonar.projectKey=HMED `
  -Dsonar.host.url=http://localhost:9000 `
  -Dsonar.login=admin `
  -Dsonar.password=admin

# O con token
sonar-scanner `
  -Dsonar.projectKey=HMED `
  -Dsonar.host.url=http://localhost:9000 `
  -Dsonar.login=<YOUR_TOKEN>
```

---

## Crear Token de Acceso

1. Abre http://localhost:9000/account/security
2. Bajo "Tokens de Seguridad", ingresa un nombre (ej: "HMED-Token")
3. Click en "Generate"
4. Copia el token y úsalo en lugar de credenciales:
```powershell
sonar-scanner -Dsonar.login=<TOKEN_AQUI>
```

---

## Reiniciar SonarQube

Si tienes problemas, reinicia el servicio:
```powershell
# Detiene el contenedor
docker-compose stop sonarqube

# Espera 5 segundos
Start-Sleep -Seconds 5

# Inicia nuevamente
docker-compose start sonarqube

# Verifica logs
docker-compose logs sonarqube -f
```

---

## Limpiar Instalación

Si necesitas empezar de cero:
```powershell
# Elimina contenedores
docker-compose down -v

# Elimina sonar-scanner
Remove-Item C:\sonar-scanner -Recurse -Force -ErrorAction SilentlyContinue

# Reinicia todo
docker-compose up -d
.\start-security-analysis.bat
```

---

## Información de Soporte

- **Documentación oficial**: https://docs.sonarqube.org/
- **Descargas**: https://www.sonarsource.com/products/sonarqube/downloads/
- **Issues conocidos**: Verifica docker-compose logs para más detalles

