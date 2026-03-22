# 🔍 SonarQube - Análisis de Código HMED

Guía completa para configurar y ejecutar análisis de código con SonarQube en el proyecto HMED.

## ¿Qué es SonarQube?

SonarQube es una plataforma de análisis estático que detecta:
- ✅ Bugs y vulnerabilidades de seguridad
- ✅ Deuda técnica y code smells
- ✅ Duplicación de código
- ✅ Cobertura de pruebas
- ✅ Estándares de codificación

## 🚀 Configuración Inicial

### 1. Instalar Sonar Scanner

**Windows:**
```powershell
# Descargar desde: https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/
# (Versión windows-x64)

# Extraer a C:\sonar-scanner (o similar)
# Agregar a PATH: C:\sonar-scanner\bin

# Verificar instalación
sonar-scanner --version
```

**Linux/Mac:**
```bash
# Opción 1: Descargar manual
cd /opt
sudo unzip sonar-scanner-x.x.x-linux.zip
sudo chown -R $USER:$USER sonar-scanner

# Opción 2: Con Homebrew (Mac)
brew install sonar-scanner

# Agregar a PATH
export PATH=$PATH:/opt/sonar-scanner/bin

# Verificar instalación
sonar-scanner --version
```

### 2. Asegurarse que SonarQube está corriendo

```powershell
# Iniciar servicios Docker
docker-compose up -d sonarqube
docker-compose up -d db

# Esperar 2-3 minutos hasta que SonarQube esté listo
# Verificar: http://localhost:9000
```

## 📊 Ejecutar Análisis

### Opción 1: Scripts Automatizados (Recomendado)

**Windows:**
```powershell
cd "c:\Users\david\OneDrive\Escritorio\historico clinico"
.\run-sonar-analysis.bat
```

**Linux/Mac:**
```bash
cd "/Users/david/OneDrive/Escritorio/historico clinico"
chmod +x run-sonar-analysis.sh
./run-sonar-analysis.sh
```

### Opción 2: Comando Manual

```bash
sonar-scanner \
  -Dsonar.projectBaseDir=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=admin
```

### Opción 3: Con Contraseña Token

Si ya cambiaste la contraseña de admin, generar token:

1. Ir a http://localhost:9000
2. Login con admin
3. Ir a **Seguridad → Tokens**
4. Crear nuevo token

```bash
sonar-scanner \
  -Dsonar.projectBaseDir=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=tu_token_aqui
```

## 📈 Ver Resultados

Después del análisis:

1. Ir a: **http://localhost:9000**
2. Click en **Proyectos** 
3. Seleccionar **hmed-full**
4. Revisar:
   - **📌 Overview** - Resumen general
   - **🐛 Issues** - Problemas encontrados
   - **📊 Measures** - Métricas de código
   - **🔒 Security** - Vulnerabilidades
   - **⚠️ Code Smells** - Problemas de diseño

## 🔧 Configuración del Proyecto

El proyecto está configurado en **`sonar-project.properties`**:

```properties
# Análisis de:
sonar.sources=backend,frontend

# Backend (Python):
sonar.python.version=3.9
sonar.python.django.enabled=true

# Frontend (JavaScript/React):
sonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info

# Credenciales:
sonar.host.url=http://localhost:9000
sonar.login=admin
sonar.password=admin
```

## 📝 Qué se Analiza

### Backend (Python/Django)
- ✅ Seguridad en autenticación
- ✅ Inyección de SQL
- ✅ Manejo de excepciones
- ✅ Complejidad del código
- ✅ Estándares PEP8

### Frontend (JavaScript/React)
- ✅ Vulnerabilidades XSS
- ✅ Componentes no usados
- ✅ Código duplicado
- ✅ Patrones de React no óptimos
- ✅ Accesibilidad (a11y)

## 🔒 Cambiar Contraseña por Defecto

**Importante para producción:**

1. Acceder a http://localhost:9000
2. Login: `admin` / `admin`
3. Se abrirá automáticamente diálogo para cambiar contraseña
4. Crear contraseña fuerte

## 📋 Ejemplos de Problemas Detectados

### Vulnerabilidades que SonarQube encuentra:

```python
# ❌ MALO - SQL Injection
def get_user(user_id):
    query = f"SELECT * FROM users WHERE id = {user_id}"  # HIGH RISK
    return db.execute(query)

# ✅ BUENO
def get_user(user_id):
    query = "SELECT * FROM users WHERE id = %s"
    return db.execute(query, (user_id,))
```

```javascript
// ❌ MALO - React missing deps
useEffect(() => {
  console.log(userId);
}, []); // userId no está en dependencies

// ✅ BUENO
useEffect(() => {
  console.log(userId);
}, [userId]);
```

## 🐛 Troubleshooting

### Error: "sonar-scanner command not found"
```bash
# Verificar si está en PATH
echo $PATH

# Agregar manualmente
export PATH=$PATH:/path/to/sonar-scanner/bin
```

### Error: "Connection refused" al SonarQube
```bash
# Verificar que SonarQube está corriendo
docker ps | grep sonarqube

# Si no está, reiniciar
docker-compose restart sonarqube
docker-compose logs -f sonarqube
```

### Error: "wrong credentials"
```bash
# Verificar credenciales en sonar-project.properties
# Por defecto:
#   Usuario: admin
#   Contraseña: admin

# O cambiar en línea de comando:
sonar-scanner \
  -Dsonar.projectBaseDir=. \
  -Dsonar.login=tu_usuario \
  -Dsonar.password=tu_contraseña
```

### El análisis es muy lento
- Primera ejecución suele ser lenta (compilación, indexación)
- Los análisis posteriores son más rápidos
- Excluir directorios grandes en `sonar-project.properties`

## 📅 Ejecutar Análisis Regularmente

**Recomendación**: Ejecutar después de cada commit importante

```bash
# En CI/CD (GitHub Actions, GitLab, etc.)
- name: Run SonarQube Analysis
  run: ./run-sonar-analysis.sh
```

## 🔗 Enlaces Útiles

- **SonarQube Docs**: https://docs.sonarqube.org/
- **Sonar Scanner**: https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/
- **Reglas del proyecto**: http://localhost:9000 → Administration → Rules
- **Gestión de usuarios**: http://localhost:9000 → Administration → Security

---

**Última actualización**: 22 de marzo de 2026
