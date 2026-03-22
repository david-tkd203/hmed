#!/usr/bin/env python
"""
Script para crear un documento de prueba para el sistema de análisis médico
Crea una imagen PNG con texto médico que simula una receta o diagnóstico
"""

import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Hmed.settings')
sys.path.insert(0, '/app')
django.setup()

from django.contrib.auth.models import User
from registros.models import MedicalDocument, RegistroClinico
from PIL import Image, ImageDraw, ImageFont
import io

def create_test_document():
    """Crear un documento de prueba con texto médico"""
    
    # Crear imagen con texto médico
    img = Image.new('RGB', (800, 1000), color='white')
    draw = ImageDraw.Draw(img)
    
    # Textos de prueba en español
    texts = [
        "RECETA MEDICA",
        "Hospital Central",
        "",
        "Paciente: Juan Pérez González",
        "Edad: 55 años",
        "Fecha: 15/03/2024",
        "",
        "DIAGNÓSTICO:",
        "- Hipertensión arterial",
        "- Presión elevada: 160/95 mmHg",
        "- Glucosa elevada: 185 mg/dL",
        "",
        "MEDICAMENTOS PRESCRITOS:",
        "1. Lisinopril 10mg - Uno diariamente",
        "   para control de presión arterial",
        "",
        "2. Metformina 500mg - Dos veces",
        "   para control de glucosa",
        "",
        "3. Atorvastatina 20mg - Antes",
        "   de dormir para colesterol",
        "",
        "OBSERVACIONES:",
        "- Se recomienda dieta baja en sal",
        "- Hacer ejercicio 30 minutos diarios",
        "- Monitorear presión arterial regularmente",
        "",
        "Médico: Dr. Carlos López Med",
        "Cédula: 123456789",
        "Fecha de firma: 15/03/2024"
    ]
    
    y_pos = 40
    try:
        # Intentar usar una fuente del sistema, si no existe usar default
        font = ImageFont.truetype("arial.ttf", 14)
        title_font = ImageFont.truetype("arial.ttf", 18)
    except:
        # Fallback a font por defecto
        font = ImageFont.load_default()
        title_font = font
    
    for text in texts:
        if text.startswith(("RECETA", "DIAGNÓSTICO", "MEDICAMENTOS", "OBSERVACIONES")):
            draw.text((20, y_pos), text, fill='black', font=title_font)
            y_pos += 30
        else:
            draw.text((20, y_pos), text, fill='black', font=font)
            y_pos += 20
    
    # Guardar la imagen
    test_doc_path = '/app/backend/documentos_medicos/test_receta.png'
    os.makedirs(os.path.dirname(test_doc_path), exist_ok=True)
    img.save(test_doc_path)
    
    print(f"✅ Imagen de prueba creada: {test_doc_path}")
    
    # Crear usuario de prueba si no existe
    user, created = User.objects.get_or_create(
        username='testuser',
        defaults={
            'email': 'test@example.com',
            'first_name': 'Test',
            'last_name': 'User'
        }
    )
    
    if created:
        print(f"✅ Usuario de prueba creado: {user.username}")
    else:
        print(f"ℹ️  Usuario de prueba ya existe: {user.username}")
    
    # Crear documento médico de prueba
    doc, created = MedicalDocument.objects.get_or_create(
        archivo='test_receta.png',
        defaults={
            'usuario': user,
            'tipo_documento': 'receta',
            'descripcion': 'Receta de prueba con OCR'
        }
    )
    
    if created:
        print(f"✅ Documento de prueba creado (ID: {doc.id})")
        print(f"   Ruta: {doc.archivo.path if doc.archivo else 'No path'}")
    else:
        print(f"ℹ️  Documento de prueba ya existe (ID: {doc.id})")
    
    return {
        'user': user,
        'document': doc,
        'image_path': test_doc_path
    }

if __name__ == '__main__':
    try:
        result = create_test_document()
        print("\n✅ Setup de prueba completado!")
        print(f"   Usuario: {result['user'].username} (ID: {result['user'].id})")
        print(f"   Documento: ID {result['document'].id}")
        print(f"   Imagen: {result['image_path']}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
