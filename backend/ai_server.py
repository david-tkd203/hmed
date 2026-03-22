#!/usr/bin/env python
"""
FastAPI server para MedSigLIP y MedGemma
Expone endpoints para análisis médico de imágenes y texto
"""
import os
import sys
import logging
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from pathlib import Path

# Agregar directorio de app al path
sys.path.insert(0, '/app')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="HMED Medical AI Service",
    description="MedSigLIP & MedGemma medical image and text analysis",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import analysis service
try:
    from registros.analysis_service import get_image_analyzer, MODELS_AVAILABLE, MEDSIGLIP_MODE
    logger.info(f"✓ Analysis service loaded. MODELS_AVAILABLE={MODELS_AVAILABLE}, MODE={MEDSIGLIP_MODE}")
except ImportError as e:
    logger.error(f"✗ Failed to import analysis service: {e}")
    MODELS_AVAILABLE = False

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "models_available": MODELS_AVAILABLE,
        "mode": MEDSIGLIP_MODE or "disabled"
    }

@app.post("/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """
    Analizar imagen médica con MedSigLIP
    
    Endpoint: POST /analyze-image
    
    Parámetro:
    - file: archivo de imagen médica (JPEG, PNG, TIFF)
    
    Retorna: embeddings, confidence, clasificación
    """
    if not MODELS_AVAILABLE:
        return JSONResponse({
            "status": "unavailable",
            "message": "AI models not installed",
            "note": "Install tensorflow and transformers to enable MedSigLIP analysis"
        }, status_code=503)
    
    try:
        # Guardar archivo temporalmente
        contents = await file.read()
        temp_path = f"/tmp/{file.filename}"
        
        with open(temp_path, 'wb') as f:
            f.write(contents)
        
        # Análisis con MedSigLIP
        analyzer = get_image_analyzer()
        if analyzer is None:
            return JSONResponse({
                "status": "error",
                "message": "Could not initialize analyzer"
            }, status_code=500)
        
        result = analyzer.analyze_image(temp_path)
        
        # Limpiar
        Path(temp_path).unlink(missing_ok=True)
        
        return {
            "status": "success",
            "filename": file.filename,
            "analysis": result
        }
    
    except Exception as e:
        logger.error(f"Error analyzing image: {str(e)}")
        return JSONResponse({
            "status": "error",
            "message": str(e)
        }, status_code=400)

@app.get("/status")
def get_status():
    """Obtener estado del servicio de IA"""
    return {
        "service": "HMED Medical AI",
        "models_available": MODELS_AVAILABLE,
        "mode": MEDSIGLIP_MODE or "disabled",
        "endpoints": {
            "/health": "Health check",
            "/status": "Service status",
            "/analyze-image": "Analyze medical image with MedSigLIP"
        }
    }

if __name__ == "__main__":
    port = int(os.getenv("AI_SERVICE_PORT", 8001))
    logger.info(f"Starting AI Service on port {port}...")
    logger.info(f"Models available: {MODELS_AVAILABLE}")
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
