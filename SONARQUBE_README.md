# SonarQube - Análisis de Seguridad HMED

## ¡Simplicidad Máxima! 🚀

Solo ejecuta:
```powershell
.\start-security-analysis.bat
```

**¡Eso es todo!** El script se encarga de todo.

---

## ¿Qué hace?

1. ✅ Verifica que Docker está corriendo
2. ✅ Verifica que SonarQube está disponible  
3. ✅ Configura el proyecto automáticamente
4. ✅ Ejecuta análisis completo usando Docker
5. ✅ Abre resultados en tu navegador

**Tiempo**: 2-5 minutos

---

## Requisitos Previos

Solo **2 cosas**:

### 1. Docker Compose debe estar ejecutando
```powershell
docker-compose up -d
```

Verifica:
```powershell
docker-compose ps
```

Deberías ver:
- `sonarqube` - UP
- `db` - UP

### 2. Espera a que SonarQube inicie (30-60 segundos)
El primer inicio toma más tiempo. Log:
```powershell
docker-compose logs sonarqube | Select-Object -Last 5
```

---

## Acceso a Resultados

**URL**: http://localhost:9000/dashboard?id=HMED

**Credenciales**:
- Usuario: `admin`
- Contraseña: `admin`

---

## Si hay problemas

### SonarQube no responde
```powershell
# Espera más tiempo
docker-compose logs sonarqube

# O reinicia
docker-compose restart sonarqube
```

### Docker no está corriendo
```powershell
# Inicia Docker Desktop (Windows)
docker ps

# Inicia los contenedores
docker-compose up -d
```

---

## Documentación Detallada

Otros archivos:
- `SONARQUBE_QUICK_START.md` - Inicio rápido
- `SONARQUBE_METHOD.md` - Detalles técnicos
- `SONARQUBE_TROUBLESHOOTING.md` - Solución de problemas

