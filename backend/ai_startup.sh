#!/bin/bash
# AI Service Startup Script
# Esta es una aplicación ficticia que simula el servicio de IA
# En realidad, el análisis se ejecuta bajo demanda en los endpoints

set -e

echo "🤖 Iniciando AI Service..."
python -c "
import logging
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    from registros.analysis_service import MODELS_AVAILABLE, MEDSIGLIP_MODE
    
    if MODELS_AVAILABLE:
        logger.info('✓ AI Service initialized')
        logger.info(f'  Mode: {MEDSIGLIP_MODE}')
    else:
        logger.warning('⚠ AI Models not available - running in fallback mode')
        logger.warning('  Install: pip install -r requirements_ai.txt')
    
    # Keep the container running
    logger.info('AI Service ready. Keeping alive...')
    while True:
        time.sleep(60)
        
except Exception as e:
    logger.error(f'✗ AI Service error: {str(e)}')
    import sys
    sys.exit(1)
"
