# 🔍 SonarQB - Auditoría de Código

## Integración completada

Se ha integrado **SonarQB Community** (herramienta de análisis estático) al proyecto para detectar:
- ✅ Vulnerabilidades de seguridad
- ✅ Code smells y malas prácticas
- ✅ Duplicación de código
- ✅ Deuda técnica
- ✅ Coverage de tests

## Acceso rápido

**Dashboard SonarQB**: http://localhost:9000

**Credenciales por defecto**:
- Usuario: `admin`
- Contraseña: `admin`

## Ejecutar análisis

### Opción 1: Script automatizado (Recomendado)
```bash
# En Windows PowerShell
bash run-sonar-analysis.sh

# O en Git Bash
./run-sonar-analysis.sh
```

### Opción 2: Comando manual
```bash
docker run --rm \
  --network="historicoclinico_hmed_network" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=historico-clinico \
  -Dsonar.sources=/usr/src/backend/registros,/usr/src/frontend/src \
  -Dsonar.host.url=http://sonarqube:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=admin
```

## Configuración

### Archivo: `sonar-project.properties`

Define qué código analizar:
```properties
sonar.projectKey=historico-clinico
sonar.sources=backend/registros,frontend/src
sonar.exclusions=**/migrations/**,**/tests/**,**/node_modules/**
```

### Docker Compose

Se agregó servicio `sonarqube` al `docker-compose.yml`:
```yaml
sonarqube:
  image: sonarqube:community
  environment:
    - SONAR_JDBC_URL=jdbc:postgresql://db:5432/sonarqube
    - SONAR_JDBC_USERNAME=admin
    - SONAR_JDBC_PASSWORD=secret_pass
  ports:
    - "9000:9000"
  depends_on:
    - db
```

## Cómo usar el dashboard

1. Abre http://localhost:9000
2. Inicia sesión con admin/admin
3. Verás el proyecto "Histórico Clínico"
4. Explora las métricas:
   - **Issues**: Bugs, vulnerabilidades, code smells
   - **Code Smells**: Malas prácticas
   - **Security Hotspots**: Puntos críticos de seguridad
   - **Duplications**: Código duplicado
   - **Coverage**: Cobertura de tests (si hay)

## Primeros pasos recomendados

1. ✅ Ejecutar análisis inicial: `bash run-sonar-analysis.sh`
2. 📊 Revisar vulnerabilidades detectadas en el dashboard
3. 🔒 Priorizar security hotspots
4. 🐛 Revisar bugs detectados
5. 📈 Establecer quality gate (umbral de calidad)

## Cambiar credenciales (Producción)

En `docker-compose.yml`, cambia:
```yaml
sonarqube:
  environment:
    - SONAR_WEB_CONTEXT=/sonarqube
    - SONAR_WEB_ENABLE_FORCE_AUTHENTICATION=true
```

Y configura usuarios desde el dashboard.

## Posibles problemas

### "Connection refused" en SonarQB
**Solución**: SonarQB tarda 2-3 minutos en inicializar. Espera y recarga.

### Network not found
**Solución**: Asegúrate de ejecutar desde el directorio del proyecto:
```bash
cd c:\Users\david\OneDrive\Escritorio\historico\ clinico
```

### Puerto 9000 en uso
**Solución**: Cambia en `docker-compose.yml`:
```yaml
ports:
  - "9001:9000"  # Accede a http://localhost:9001
```

## Próximos pasos

- 📋 Integrar análisis en CI/CD (GitHub Actions)
- 🔐 Configurar quality gates automáticas
- 📈 Agregar métricas de coverage con pytest/Jest
- 🚀 Ejecutar análisis antes de cada merge

## Recursos

- [Documentación SonarQB](https://docs.sonarqube.org/latest/)
- [SonarQB Community vs Enterprise](https://www.sonarsource.com/products/sonarqube/downloads/)
- [SonarQube Rules](https://rules.sonarsource.com/)
