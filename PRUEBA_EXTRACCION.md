# 🧪 Guía de Prueba - Sistema de Análisis Médico

## Descripción

Este documento describe cómo probar el sistema de extracción de información médica que acabamos de implementar.

## Cambios Realizados

### 1. **Backend - Función de Extracción** ✅
- Archivo: `backend/registros/analysis_service.py`
- Nueva función: `extract_medical_findings(file_path)`
- Capacidades:
  - Extrae texto de PDFs usando PyPDF2
  - Extrae texto de imágenes usando pytesseract (OCR)
  - Detecta tipo de documento (5 tipos)
  - Identifica medicamentos (15 comunes)
  - Detecta hallazgos clínicos (8 categorías)
  - Extrae observaciones clínicas

### 2. **Backend - Endpoint de Extracción** ✅
- Archivo: `backend/registros/views.py`
- Nuevo endpoint: `POST /api/documents/{doc_id}/extract-findings/`
- Autenticado con JWT
- Verifica propiedad del documento
- Retorna información estructurada

### 3. **Frontend - Pestaña de Extracción** ✅
- Archivo: `frontend/src/components/AnalysisResults.jsx`
- Nuevo componente: `ExtractionTab`
- Muestra:
  - ✅ Tipo de documento detectado
  - ✅ Medicamentos encontrados (con emoji 💊)
  - ✅ Hallazgos detectados (con emoji 🔍)
  - ✅ Observaciones clínicas (con emoji 📝)
  - ✅ Texto extraído (primeros 500 caracteres)

### 4. **Frontend - Integración Automática** ✅
- Archivo: `frontend/src/DocumentUpload.jsx`
- Cuando se analiza un documento ahora:
  1. Llama a `/api/documents/{id}/analyze/` (embeddings)
  2. Luego llama a `/api/documents/{id}/extract-findings/` (información médica)
  3. Muestra modal con ExtractionTab por defecto
  4. Usuario puede ver ambas pestañas

### 5. **Traducciones Multiidioma** ✅
- Archivos: 
  - `frontend/src/i18n/es.json` (Español)
  - `frontend/src/i18n/en.json` (Inglés)
  - `frontend/src/i18n/pt.json` (Portugués)
- Nuevas claves:
  - `analysis.tabExtraction` - Pestaña de extracción
  - `analysis.documentType` - Tipo de documento
  - `analysis.medications` - Medicamentos
  - `analysis.findings` - Hallazgos
  - `analysis.observations` - Observaciones
  - Y más...

### 6. **Docker - Sistema OCR** ✅
- Archivo: `backend/Dockerfile`
- Agregado: `tesseract-ocr` (binario para OCR)
- Ahora pytesseract puede procesar imágenes

## Pasos para Probar

### Paso 1: Reiniciar Docker

```bash
cd "c:\Users\david\OneDrive\Escritorio\historico clinico"

# Detener contenedores existentes
docker-compose down -v

# Construir y iniciar con nuevas configuraciones
docker-compose up --build
```

**Esperar a ver:**
```
✅ web_1      | Starting development server at http://0.0.0.0:8000/
✅ frontend_1 | VITE v4.x.x  ready in xxx ms
✅ All 4 services running (db, web, frontend, ai)
```

### Paso 2: Crear Usuario y Documento de Prueba

```bash
# En otra terminal
cd backend

# Ejecutar migraciones
docker-compose exec web python manage.py migrate

# Crear documento de prueba
docker-compose exec web python scripts/create_test_document.py
```

**Esperar a ver:**
```
✅ Usuario de prueba creado: testuser
✅ Imagen de prueba creada: /app/backend/documentos_medicos/test_receta.png
✅ Documento de prueba creado (ID: 1)
✅ Setup de prueba completado!
```

### Paso 3: Acceder al Frontend

1. Abrir navegador: http://localhost:5173
2. Ir a **Login**
3. Ingresar credenciales:
   - **Usuario:** `testuser`
   - **Contraseña:** (la que deberías haber configurado o crear nueva)

**⚠️ Si no recuerdas la contraseña:**
Ejecuta en Docker:
```bash
docker-compose exec web python manage.py shell

# Dentro del shell:
from django.contrib.auth.models import User
user = User.objects.get(username='testuser')
user.set_password('123456')  # Cambiar la contraseña
user.save()
```

### Paso 4: Subir y Analizar Documento

1. En el frontend, ir a **Documentos** o **Home**
2. Hacer clic en **"Subir Documento"**
3. Seleccionar un archivo:
   - Opción A: Usar el documento de prueba creado en `/backend/documentos_medicos/test_receta.png`
   - Opción B: Subir tu propio PDF o imagen con texto médico

4. Esperar a que complete la carga
5. Hacer clic en **"Analizar con IA"**

**Flujo esperado:**
```
1. Modal abre con spinner "Analizando imagen médica..."
2. Después de 2-3 segundos, automáticamente aparece segunda búsqueda
3. Spinner dice "Extrayendo información del documento..."
4. Modal usa pestaña "Extracción" por defecto
5. Ves:
   ✅ Tipo de Documento: "Receta Médica"
   ✅ Medicamentos: Lisinopril, Metformina, Atorvastatina
   ✅ Hallazgos: presión alta, glucosa elevada, colesterol elevado
   ✅ Observaciones: [3 observaciones extraídas]
   ✅ Texto Extraído: [primeros 500 caracteres del OCR]
```

### Paso 5: Probar Diferentes Idiomas

1. En el modal superior derecho, cambiar idioma a:
   - 🇪🇸 Español (ES)
   - 🇬🇧 English (EN)
   - 🇧🇷 Português (PT)

2. Las etiquetas en la pestaña "Extracción" deben cambiar automáticamente

**Confirmación de traducción:**
```
ES: "Extracción" → EN: "Extraction" → PT: "Extração"
ES: "Medicamentos Encontrados" → EN: "Medications Found" → PT: "Medicamentos Encontrados"
```

## Estructura de Respuesta del Endpoint

**GET** `/api/documents/{doc_id}/extract-findings/`

```json
{
  "id": 1,
  "message": "Información extraída exitosamente",
  "extraction": {
    "status": "success",
    "document_type": "Receta Médica",
    "medications": [
      "Lisinopril",
      "Metformina",
      "Atorvastatina"
    ],
    "findings": [
      "presión alta",
      "glucosa elevada",
      "colesterol elevado"
    ],
    "observations": [
      "Se recomienda dieta baja en sal",
      "Hacer ejercicio 30 minutos diarios",
      "Monitorear presión arterial regularmente"
    ],
    "extracted_text": "RECETA MEDICA Hospital Central Paciente: Juan Pérez González...",
    "text_length": 847
  }
}
```

## Pruebas Adicionales

### Test 1: PDF Real
Si tienes un PDF médico real:
1. Guardarlo en `c:\Users\david\OneDrive\Escritorio\historico clinico\test_files\`
2. Subirlo desde el frontend
3. Verificar que PyPDF2 extrae el texto correctamente

### Test 2: Imagen con OCR
1. Tomar una foto de un documento médico real
2. Subirla como PNG o JPG
3. Verificar que pytesseract reconoce el texto

### Test 3: Diferentes Documentos
Prueba con estos tipos de documentos:
- ✅ Receta Médica (medications → detecta)
- ✅ Reporte de Laboratorio (laboratorio, análisis → detecta)
- ✅ Imagen Diagnóstica (radiografía, ecografía → detecta)
- ✅ Reporte Oftalmológico (óptico, oftalmología → detecta)
- ✅ Prueba de Alergia (alergia → detecta)

## Problemas Comunes y Soluciones

### ❌ Problema: "pytesseract.TesseractNotFoundError"
**Causa:** Tesseract no está instalado en Docker
**Solución:**
```bash
docker-compose rebuild web
```

### ❌ Problema: "PyPDF2.utils.PdfReadError"
**Causa:** PDF corrupto o formato no soportado
**Solución:**
- Usar PDF limpio con texto
- Convertir a imagen PNG si es necesario

### ❌ Problema: Modal no muestra ExtraccionTab
**Causa:** extractionData = null
**Solución:**
Revisar en browser console:
```javascript
console.log('✅ Análisis completado:', response.data);
console.log('✅ Información extraída:', extraction);
```

### ❌ Problema: Traducción no aparece
**Causa:** Clave no existe en i18n JSON
**Solución:**
```bash
# Verificar que la clave existe:
grep "tabExtraction" frontend/src/i18n/es.json
# Debería retornar: "tabExtraction": "Extracción",
```

## Logs Útiles

### Para ver logs del backend:
```bash
docker-compose logs web -f
```

### Para ver logs del frontend:
```bash
docker-compose logs frontend -f
```

### Para ver logs de Docker build:
```bash
docker-compose up -d web --build
docker-compose logs web
```

## Próximos Pasos Después de Prueba

Si todo funciona:

1. **Mejorar OCR:**
   - Agregar preprocesamiento de imagen (rotación, binarización)
   - Usar YOLO para detectar regiones de texto

2. **Expandir Bases de Datos:**
   - Agregar 50+ medicamentos más
   - Agregar 20+ hallazgos médicos más
   - Soportar síntomas en tiempo real

3. **Implementar Modelos Reales:**
   - Cargar MedSigLIP para análisis de imagen
   - Cargar MedGemma para análisis de texto complejo

4. **Agregar Clasificación:**
   - Usar el endpoint `/api/documents/{id}/classify/`
   - Clasificar tipo de especialidad médica

5. **Agregar Búsqueda Similar:**
   - Usar embeddings para encontrar documentos similares
   - Crear índice de búsqueda semántica

## Rollback si No Funciona

Si necesitas volver atrás:

```bash
git log --oneline
# Encontrar commit previo

git reset --hard <commit_hash>
docker-compose down -v
docker-compose up --build
```

---

**Fecha de Implementación:** 15/03/2024
**Version:** 1.0
**Estado:** ✅ LISTO PARA PRUEBAS
