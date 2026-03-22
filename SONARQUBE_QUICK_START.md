# SonarQube - Inicio Rápido

## ¡Lo Más Simple Posible! 🎯

```powershell
.\start-security-analysis.bat
```

**Espera 2-5 minutos. ¡Listo!** Los resultados se abrirán en tu navegador.

---

## Prerequisitos (2 cosas)

### 1. Docker Compose corriendo
```powershell
docker-compose up -d
```

### 2. Esperar a que SonarQube inicie
```powershell
# Verifica en los logs
docker-compose logs sonarqube | Select-Object -Last 5
```

Si ves: `SonarQube is operational` ✅ - ¡Listo!

---

## Acceder a Resultados

Una vez completado, se abre automáticamente:

**http://localhost:9000/dashboard?id=HMED**

credenciales:
- Usuario: `admin`
- Contraseña: `admin`

---

## ¿Qué hace el script?

```
✅ Verifica Docker
✅ Verifica SonarQube
✅ Configura proyecto
✅ Analiza código
✅ Abre resultados
```

No necesitas:
- ❌ Instalar Java
- ❌ Descargar sonar-scanner
- ❌ Configurar PATH
- ❌ Tokens manuales

**Todo es automático**

---

## Si hay problemas

| Problema | Solución |
|----------|----------|
| Docker no corre | `docker ps` - Abre Docker Desktop |
| SonarQube no responde | `docker-compose restart sonarqube` |
| Análisis lento | Es normal (2-5 minutos primera vez) |
| Error de red | `docker-compose up -d` reinicia todo |

---

## Métodos Alternativos

### Desde Bash
```bash
bash run-sonar-analysis.sh
```

### Validar antes de ejecutar
```powershell
.\validate-sonarqube.bat
.\start-security-analysis.bat
```

---

## Más Información

- Detalles técnicos: `SONARQUBE_METHOD.md`
- Troubleshooting: `SONARQUBE_TROUBLESHOOTING.md`
- Documentación completa: `SONARQUBE_README.md`

