# SonarQube - Scripts Disponibles

## 🚀 Para Ejecutar Análisis de Seguridad

### Script Principal (recomendado)
```powershell
.\start-security-analysis.bat
```

**Hace todo automáticamente**:
- ✅ Verifica Docker
- ✅ Verifica SonarQube
- ✅ Instala sonar-scanner
- ✅ Configura el proyecto
- ✅ Ejecuta análisis
- ✅ Abre resultados

**Duración**: 2-5 minutos

---

## 🔍 Para Validar Configuración

```powershell
.\validate-sonarqube.bat
```

**Verifica**:
- ✅ Docker está corriendo
- ✅ SonarQube está accesible
- ✅ sonar-scanner está instalado
- ✅ Estructura del proyecto
- ✅ Espacio en disco

**Ejecuta esto ANTES si tienes dudas**

---

## 📥 Para Descargar SonarScanner Manualmente

```powershell
.\download-sonar-scanner.bat
```

**Útil si**:
- La descarga automática falla
- Tienes problemas de conectividad
- Prefieres controlarlo manualmente

---

## 🗂️ Archivos de Configuración

| Archivo | Descripción |
|---------|-------------|
| `sonar-project.properties` | Configuración del proyecto (generada automáticamente) |
| `SONARQUBE_README.md` | Instrucciones completas |
| `SONARQUBE_TROUBLESHOOTING.md` | Solución de problemas |

---

## 📋 Flujo Recomendado

### Primera Ejecución
```powershell
# 1. Valida que todo está bien
.\validate-sonarqube.bat

# 2. Si hay errores, consulta SONARQUBE_TROUBLESHOOTING.md
# 3. Si todo OK, ejecuta análisis
.\start-security-analysis.bat
```

### Ejecuciones Posteriores
```powershell
# Solo ejecuta
.\start-security-analysis.bat
```

### Si Tienes Problemas
```powershell
# 1. Lee SONARQUBE_TROUBLESHOOTING.md
# 2. Descarga manualmente sonar-scanner si es necesario
.\download-sonar-scanner.bat
# 3. Valida nuevamente
.\validate-sonarqube.bat
```

---

## 🔧 Solución Rápida para Problemas Comunes

| Problema | Solución |
|----------|----------|
| Docker no corre | Abre Docker Desktop |
| SonarQube no responde | Espera 30-60 segundos o reinicia: `docker-compose restart sonarqube` |
| Descarga falla | Ejecuta: `.\download-sonar-scanner.bat` |
| Error 403 en descarga | Usa el script de descarga manual |
| Análisis muy lento | Normal, toma 2-5 minutos la primera vez |

---

## 📊 Acceder a los Resultados

**URL**: http://localhost:9000/dashboard?id=HMED

**Credenciales**:
- Usuario: `admin`
- Contraseña: `admin`

---

## 📚 Documentación Detallada

- Instrucciones completas: `SONARQUBE_README.md`
- Troubleshooting: `SONARQUBE_TROUBLESHOOTING.md`
- Configuración manual: `sonar-project.properties`

