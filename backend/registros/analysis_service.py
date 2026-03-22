"""
Service para análisis de imágenes médicas usando MedSigLIP de Google Health AI

MedSigLIP es un encoder de imagen-texto médico optimizado para:
- Radiografías de tórax
- Ecografías
- Histopatología
- Dermatología

GitHub: https://github.com/google-health/medsiglip
Uso: Analiza imágenes médicas y genera embeddings para clasificación y búsqueda
"""

import logging
from typing import Dict, List, Tuple, Optional
import io
import json
from PIL import Image
import numpy as np
# import cv2  # Lazy-loaded if needed - avoids libGL.so.1 error in headless environments

logger = logging.getLogger(__name__)

# ==================== CONSTANTES ====================
ESPECIALIDAD_OFTALMOLOGIA = 'oftalmología'

# Intentar cargar las dependencias de IA de Google Health
MODELS_AVAILABLE = False
MEDSIGLIP_MODE = None  # 'local' o 'vertex-ai'

AutoModel = None
AutoProcessor = None
aiplatform = None
tf = None

try:
    # Intentar cargar MedSigLIP localmente (requiere TensorFlow lightweight, no PyTorch)
    from transformers import AutoModel, AutoProcessor
    import tensorflow as tf
    logger.info("✓ TensorFlow + Transformers available - using MedSigLIP locally")
    MODELS_AVAILABLE = True
    MEDSIGLIP_MODE = 'local'
except ImportError as e1:
    logger.warning(f"⚠ TensorFlow/Transformers not available: {e1}")
    try:
        # Alternativa: Usar Vertex AI API de Google
        from google.cloud import aiplatform
        logger.info("✓ Google Cloud SDK available - using Vertex AI API for MedSigLIP")
        MODELS_AVAILABLE = True
        MEDSIGLIP_MODE = 'vertex-ai'
    except ImportError as e2:
        logger.warning(f"⚠ Google Cloud SDK not available: {e2}")
        logger.warning("→ Running in fallback mode. AI analysis will return mock data.")
        MODELS_AVAILABLE = False

# Configuración de modelos
MODEL_CONFIG = {
    'medsiglip': {
        'model_id': 'google/medsiglip-448',
        'description': 'Medical image-text encoder (448x448)',
        'supported_tasks': ['classification', 'retrieval', 'embedding'],
    },
    'medgemma': {
        'model_id': 'google/medgemma-2b',
        'description': 'Medical text generation (2B parameters)',
        'supported_tasks': ['text_generation', 'report_generation'],
    }
}

class MedSigLIPAnalyzer:
    """
    Analizador de imágenes médicas usando MedSigLIP de Google
    
    Características:
    - Análisis de radiografías, ecografías, etc.
    - Generación de embeddings para búsqueda semántica
    - Clasificación de hallazgos médicos
    - Optimizado para dispositivos edge
    """
    
    _instance = None
    _model = None
    _processor = None
    
    def __new__(cls):
        """Singleton pattern para cargar modelo solo una vez"""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        """Inicializar analizador y cargar modelo si no está cargado"""
        if self._initialized:
            return
            
        if not MODELS_AVAILABLE:
            raise RuntimeError(
                "Modelos AI no disponibles. "
                "Instala: pip install -r requirements_ai.txt"
            )
        
        if AutoProcessor is None or AutoModel is None:
            raise RuntimeError(
                "AutoProcessor/AutoModel not available. "
                "Install transformers: pip install transformers tensorflow"
            )
        
        try:
            logger.info("Cargando MedSigLIP desde Hugging Face...")
            model_id = MODEL_CONFIG['medsiglip']['model_id']
            
            # Cargar modelo y procesador
            self.__class__._processor = AutoProcessor.from_pretrained(model_id)
            self.__class__._model = AutoModel.from_pretrained(model_id)
            
            # Mover a GPU si está disponible (TensorFlow)
            if tf is not None:
                import tensorflow as tensorflow_module
                device = "cuda" if tensorflow_module.config.list_physical_devices('GPU') else "cpu"
                logger.info(f"MedSigLIP cargado en {device}")
            else:
                logger.info("MedSigLIP cargado en CPU")
            
            self._initialized = True
            
        except Exception as e:
            logger.error(f"Error cargando MedSigLIP: {str(e)}")
            raise
    
    def analyze_image(self, 
                     image_path: str,
                     query: Optional[str] = None) -> Dict:
        """
        Analizar imagen médica con MedSigLIP
        
        Args:
            image_path: ruta a la imagen
            query: (opcional) texto para búsqueda semántica
                   ej: "radiografía de tórax normal"
        
        Returns:
            Dict con análisis: embedding, clasificación, similitud
        """
        try:
            # Cargar imagen
            image = Image.open(image_path).convert('RGB')
            
            # Validar tamaño
            if image.size[0] > 2000 or image.size[1] > 2000:
                image.thumbnail((2000, 2000))
                logger.warning(f"Imagen reducida a {image.size}")
            
            # Procesar entrada
            if query:
                inputs = self.__class__._processor(
                    images=image,
                    text=query,
                    return_tensors="pt",
                    padding=True
                )
            else:
                inputs = self.__class__._processor(
                    images=image,
                    return_tensors="pt"
                )
            
            # Mover a device
            for key in inputs:
                if hasattr(inputs[key], 'to'):
                    inputs[key] = inputs[key].to(self.device)
            
            # Inferencia
            with torch.no_grad():
                outputs = self.__class__._model(**inputs)
            
            # Extraer embeddings
            image_embedding = outputs.image_embeddings[0].cpu().numpy()
            
            result = {
                'status': 'success',
                'image_embedding': image_embedding.tolist(),
                'embedding_dims': image_embedding.shape[0],
                'device': self.device,
            }
            
            # Si hay query, calcular similitud
            if query and hasattr(outputs, 'text_embeddings'):
                text_embedding = outputs.text_embeddings[0].cpu().numpy()
                
                # Calcular similitud coseno
                similarity = self._cosine_similarity(
                    image_embedding,
                    text_embedding
                )
                
                result.update({
                    'query': query,
                    'text_embedding': text_embedding.tolist(),
                    'cosine_similarity': float(similarity),
                    'match_percentage': float(similarity * 100),
                })
            
            logger.info(f"Análisis completado para imagen")
            return result
            
        except Exception as e:
            logger.error(f"Error analizando imagen: {str(e)}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    def batch_analyze_images(self,
                            image_paths: List[str]) -> List[Dict]:
        """
        Analizar múltiples imágenes en batch
        
        Args:
            image_paths: lista de rutas de imágenes
        
        Returns:
            Lista de análisis para cada imagen
        """
        results = []
        for path in image_paths:
            result = self.analyze_image(path)
            results.append(result)
        return results
    
    def classify_finding(self,
                        image_path: str,
                        findings: List[str]) -> Dict:
        """
        Clasificar hallazgos en imagen médica
        
        Ejemplos:
            findings = [
                "radiografía de tórax normal",
                "neumonía bilateral",
                "edema pulmonar",
                "derrame pleural"
            ]
        
        Args:
            image_path: ruta a imagen
            findings: lista de hallazgos posibles
        
        Returns:
            Dict con similitudes a cada hallazgo
        """
        try:
            image = Image.open(image_path).convert('RGB')
            similarities = {}
            
            for finding in findings:
                result = self.analyze_image(image_path, query=finding)
                if result['status'] == 'success':
                    similarities[finding] = {
                        'similarity': result.get('cosine_similarity', 0),
                        'confidence': result.get('match_percentage', 0),
                    }
            
            # Ordenar por similitud
            sorted_findings = sorted(
                similarities.items(),
                key=lambda x: x[1]['similarity'],
                reverse=True
            )
            
            return {
                'status': 'success',
                'findings': dict(sorted_findings),
                'top_finding': sorted_findings[0] if sorted_findings else None,
            }
            
        except Exception as e:
            logger.error(f"Error clasificando hallazgos: {str(e)}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    def search_similar_images(self,
                             image_path: str,
                             reference_embeddings: List[Tuple[str, List[float]]],
                             top_k: int = 5) -> List[Dict]:
        """
        Buscar imágenes similares usando embeddings
        
        Args:
            image_path: ruta a imagen de consulta
            reference_embeddings: lista de (nombre, embedding) referencias
            top_k: cantidad de resultados a retornar
        
        Returns:
            Lista de coincidencias ordenadas por similitud
        """
        try:
            # Analizar imagen de consulta
            query_result = self.analyze_image(image_path)
            
            if query_result['status'] != 'success':
                return []
            
            query_embedding = np.array(query_result['image_embedding'])
            
            # Calcular similitud con referencia
            similarities = []
            for name, ref_embedding in reference_embeddings:
                sim = self._cosine_similarity(
                    query_embedding,
                    np.array(ref_embedding)
                )
                similarities.append({
                    'name': name,
                    'similarity': float(sim),
                    'confidence': float(sim * 100),
                })
            
            # Ordenar y retornar top-k
            sorted_results = sorted(
                similarities,
                key=lambda x: x['similarity'],
                reverse=True
            )
            
            return sorted_results[:top_k]
            
        except Exception as e:
            logger.error(f"Error buscando imágenes similares: {str(e)}")
            return []
    
    def search_similar_by_embeddings(self,
                                      reference_embedding: List[float],
                                      comparison_embeddings: List[List[float]],
                                      top_k: int = 5) -> List[Tuple[float, int]]:
        """
        Buscar imágenes similares usando embeddings precalculados
        
        Args:
            reference_embedding: embedding vector del documento de referencia
            comparison_embeddings: lista de embeddings para comparar
            top_k: cantidad de resultados a retornar
        
        Returns:
            Lista de tuplas (similarity_score, index) ordenadas por similitud descendente
        """
        try:
            if not reference_embedding or not comparison_embeddings:
                logger.warning("Embeddings vacíos para búsqueda")
                return []
            
            ref_embedding = np.array(reference_embedding)
            
            # Calcular similitud con cada documento
            similarities = []
            for idx, comp_embedding in enumerate(comparison_embeddings):
                comp_array = np.array(comp_embedding)
                sim = self._cosine_similarity(ref_embedding, comp_array)
                similarities.append((sim, idx))
            
            # Ordenar por similitud descendente
            sorted_similarities = sorted(similarities, key=lambda x: x[0], reverse=True)
            
            # Retornar top-k resultados
            return sorted_similarities[:top_k]
            
        except Exception as e:
            logger.error(f"Error buscando embeddings similares: {str(e)}")
            return []
    
    @staticmethod
    def _cosine_similarity(vec1: "np.ndarray", vec2: "np.ndarray") -> float:
        """Calcular similitud coseno entre dos vectores"""
        dot_product = np.dot(vec1, vec2)
        norm_vec1 = np.linalg.norm(vec1)
        norm_vec2 = np.linalg.norm(vec2)
        
        if norm_vec1 == 0 or norm_vec2 == 0:
            return 0.0
        
        return float(dot_product / (norm_vec1 * norm_vec2))
    
    def get_model_info(self) -> Dict:
        """Obtener información del modelo cargado"""
        return {
            'model': MODEL_CONFIG['medsiglip'],
            'device': self.device,
            'model_loaded': self.__class__._model is not None,
            'processor_loaded': self.__class__._processor is not None,
        }


class MedicalImageProcessor:
    """Procesador de imágenes médicas con validación y conversión"""
    
    SUPPORTED_FORMATS = ['JPEG', 'PNG', 'TIFF']
    MAX_RESOLUTION = 2048
    
    @staticmethod
    def validate_medical_image(image_path: str) -> Tuple[bool, Optional[str]]:
        """
        Validar imagen médica
        
        Returns:
            Tupla (es_valida, mensaje_error)
        """
        try:
            image = Image.open(image_path)
            
            # Validar formato
            if image.format not in MedicalImageProcessor.SUPPORTED_FORMATS:
                return False, f"Formato no soportado: {image.format}"
            
            # Validar modo
            if image.mode not in ['RGB', 'L', 'LA', 'RGBA']:
                return False, f"Modo de imagen no soportado: {image.mode}"
            
            # Validar resolución
            if max(image.size) > MedicalImageProcessor.MAX_RESOLUTION:
                return False, f"Resolución muy alta: {image.size}"
            
            return True, None
            
        except Exception as e:
            return False, str(e)
    
    @staticmethod
    def convert_to_rgb(image_path: str) -> "Image.Image":
        """Convertir imagen a RGB"""
        image = Image.open(image_path)
        if image.mode != 'RGB':
            image = image.convert('RGB')
        return image


class MedGemmaAnalyzer:
    """
    Analizador de documentos médicos usando MedGemma 2B de Google Health AI
    
    Características:
    - Extracción de información clínica de textos
    - Análisis y resumen de reportes médicos
    - Extracción de medicamentos, diagnósticos, tratamientos
    - Clasificación de tipos de documentos
    - Generación de análisis estructurado
    """
    
    _instance = None
    _model = None
    _tokenizer = None
    
    def __new__(cls):
        """Singleton pattern para cargar modelo solo una vez"""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        """Inicializar analizador y cargar modelo si no está cargado"""
        if self._initialized:
            return
            
        if not MODELS_AVAILABLE:
            raise RuntimeError(
                "Modelos AI no disponibles. "
                "Instala: pip install -r requirements_ai.txt"
            )
        
        try:
            logger.info("Cargando MedGemma 2B desde Hugging Face...")
            
            # Cargar tokenizador y modelo
            from transformers import AutoTokenizer, AutoModelForCausalLM
            
            model_id = 'google/medgemma-2b'
            self.__class__._tokenizer = AutoTokenizer.from_pretrained(model_id)
            self.__class__._model = AutoModelForCausalLM.from_pretrained(model_id)
            
            # Mover a GPU si está disponible
            device = "cuda" if torch.cuda.is_available() else "cpu"
            self.__class__._model = self.__class__._model.to(device)
            self.__class__._model.eval()
            
            self.device = device
            self._initialized = True
            logger.info(f"MedGemma cargado exitosamente en {device}")
            
        except Exception as e:
            logger.error(f"Error cargando MedGemma: {str(e)}")
            raise
    
    def extract_medical_info(self, text: str, max_length: int = 500) -> Dict:
        """
        Extraer información médica de un texto
        
        Returns:
            Dict con medicamentos, diagnósticos, tratamientos, síntomas
        """
        try:
            prompt = f"""Analiza el siguiente texto médico y extrae:
1. Medicamentos (nombre, dosis, frecuencia)
2. Diagnósticos
3. Síntomas
4. Tratamientos recomendados
5. Restricciones/Contraindicaciones
6. Seguimiento recomendado

Texto médico:
{text}

Responde en formato JSON estructurado."""

            return self._generate_response(prompt, max_length=max_length)
            
        except Exception as e:
            logger.error(f"Error extrayendo información médica: {str(e)}")
            return {'status': 'error', 'error': str(e)}
    
    def summarize_report(self, text: str, max_length: int = 300) -> Dict:
        """
        Generar resumen ejecutivo de un reporte médico
        
        Returns:
            Dict con resumen estructurado
        """
        try:
            prompt = f"""Resume el siguiente reporte médico en máximo 3 párrafos.
Incluye:
- Hallazgos principales
- Diagnóstico
- Recomendaciones

Reporte:
{text[:2000]}

Proporciona un resumen conciso y profesional."""

            return self._generate_response(prompt, max_length=max_length)
            
        except Exception as e:
            logger.error(f"Error resumiendo reporte: {str(e)}")
            return {'status': 'error', 'error': str(e)}
    
    def classify_document_type(self, text: str) -> Dict:
        """
        Clasificar tipo de documento médico
        
        Returns:
            Dict con tipo probable y confianza
        """
        try:
            types = [
                'Radiografía', 'Análisis de Laboratorio', 'Ecografía',
                'Tomografía', 'Resonancia Magnética', 'Informe Médico',
                'Receta Médica', 'Historia Clínica', 'Nota de Evolución'
            ]
            
            prompt = f"""Clasifica el siguiente documento médico.
Selecciona UNA de estas opciones: {', '.join(types)}

Documento:
{text[:1500]}

Responde solo con el tipo de documento, sin explicaciones."""

            result = self._generate_response(prompt, max_length=50)
            
            return {
                'status': 'success',
                'document_type': result.get('response', 'Documento Médico'),
            }
            
        except Exception as e:
            logger.error(f"Error clasificando documento: {str(e)}")
            return {'status': 'error', 'error': str(e)}
    
    def detect_symptoms_and_diseases(self, text: str) -> Dict:
        """
        Detectar síntomas y enfermedades en el texto
        
        Returns:
            Dict con síntomas y enfermedades identificadas
        """
        try:
            prompt = f"""Identifica todos los síntomas y enfermedades mencionados en el siguiente texto médico.

Texto:
{text}

Proporciona listas separadas para:
1. Síntomas
2. Enfermedades/Diagnósticos
3. Hallazgos clínicos

Sé específico y detallado."""

            return self._generate_response(prompt, max_length=400)
            
        except Exception as e:
            logger.error(f"Error detectando síntomas: {str(e)}")
            return {'status': 'error', 'error': str(e)}
    
    def extract_prescription(self, text: str) -> Dict:
        """
        Extraer detalles de prescripción farmacéutica
        
        Returns:
            Dict con medicamentos y sus detalles
        """
        try:
            prompt = f"""Extrae los medicamentos prescritos del siguiente texto.
Para cada medicamento incluye:
- Nombre
- Dosis
- Frecuencia
- Duración
- Vía de administración
- Contraindicaciones (si aplica)

Texto:
{text}

Estructura la respuesta como lista ordenada."""

            return self._generate_response(prompt, max_length=500)
            
        except Exception as e:
            logger.error(f"Error extrayendo prescripción: {str(e)}")
            return {'status': 'error', 'error': str(e)}
    
    def _generate_response(self, prompt: str, max_length: int = 300) -> Dict:
        """
        Generar respuesta usando MedGemma
        
        Args:
            prompt: texto para el modelo
            max_length: longitud máxima de respuesta
        
        Returns:
            Dict con respuesta
        """
        try:
            inputs = self.__class__._tokenizer(
                prompt,
                return_tensors="pt",
                truncation=True,
                max_length=1024
            )
            
            # Mover a device
            for key in inputs:
                if hasattr(inputs[key], 'to'):
                    inputs[key] = inputs[key].to(self.device)
            
            # Generar texto
            with torch.no_grad():
                outputs = self.__class__._model.generate(
                    **inputs,
                    max_length=max_length,
                    temperature=0.7,
                    top_p=0.9,
                    do_sample=True,
                    pad_token_id=self.__class__._tokenizer.eos_token_id,
                )
            
            response_text = self.__class__._tokenizer.decode(
                outputs[0],
                skip_special_tokens=True
            )
            
            # Limpiar respuesta
            response_text = response_text.replace(prompt, '').strip()
            
            return {
                'status': 'success',
                'response': response_text,
                'length': len(response_text),
                'model': 'MedGemma 2B',
            }
            
        except Exception as e:
            logger.error(f"Error generando respuesta: {str(e)}")
            return {'status': 'error', 'error': str(e)}


class DocumentOCRExtractor:
    """
    Extractor de texto de documentos médicos (PDFs, imágenes)
    Usa OCR y procesamiento de imágenes
    """
    
    @staticmethod
    def extract_from_image(image_path: str) -> Dict:
        """
        Extraer texto de imagen médica usando OCR
        
        Nota: Requiere pytesseract y tesseract instalados
        """
        try:
            try:
                import pytesseract
            except ImportError:
                logger.warning("pytesseract no disponible, usando extracción básica")
                return {'status': 'warning', 'text': ''}
            
            image = Image.open(image_path)
            
            # Preprocesar imagen
            if image.size[0] > 2000 or image.size[1] > 2000:
                image.thumbnail((2000, 2000))
            
            # Convertir a escala de grises para mejor OCR
            if image.mode != 'L':
                image = image.convert('L')
            
            # Extraer texto
            text = pytesseract.image_to_string(
                image,
                lang='spa+eng',  # Español e Inglés
                config='--psm 3'
            )
            
            return {
                'status': 'success',
                'text': text,
                'source': 'OCR',
                'confidence': 'medium',
            }
            
        except Exception as e:
            logger.error(f"Error extrayendo texto de imagen: {str(e)}")
            return {'status': 'error', 'error': str(e)}
    
    @staticmethod
    def extract_from_pdf(pdf_path: str) -> Dict:
        """
        Extraer texto de PDF médico
        
        Nota: Requiere PyPDF2 o pdfplumber
        """
        try:
            try:
                import PyPDF2
                pdf_available = True
            except ImportError:
                pdf_available = False
                logger.warning("PyPDF2 no disponible")
            
            if not pdf_available:
                return {'status': 'error', 'error': 'PyPDF2 no instalado'}
            
            text = ""
            with open(pdf_path, 'rb') as pdf_file:
                reader = PyPDF2.PdfReader(pdf_file)
                for page in reader.pages:
                    text += page.extract_text() + "\n"
            
            return {
                'status': 'success',
                'text': text.strip(),
                'pages': len(reader.pages),
                'source': 'PDF',
            }
            
        except Exception as e:
            logger.error(f"Error extrayendo texto de PDF: {str(e)}")
            return {'status': 'error', 'error': str(e)}


# ==================== FUNCIONES DE ACCESO ====================

def get_image_analyzer() -> MedSigLIPAnalyzer:
    """Obtener instancia de analizador de imágenes
    
    Retorna None si los modelos no están disponibles
    """
    if not MODELS_AVAILABLE:
        logger.debug("AI models not available - returning None")
        return None
    
    try:
        return MedSigLIPAnalyzer()
    except Exception as e:
        logger.error(f"Error creating analyzer: {str(e)}")
        return None


def get_text_analyzer() -> MedGemmaAnalyzer:
    """Obtener instancia de analizador de texto"""
    return MedGemmaAnalyzer()


def get_ocr_extractor() -> DocumentOCRExtractor:
    """Obtener instancia de extractor OCR"""
    return DocumentOCRExtractor()


# Alias para compatibilidad
def get_analyzer() -> MedSigLIPAnalyzer:
    """Compatibilidad hacia atrás"""
    return get_image_analyzer()


# ==================== EXTRACCIÓN DE INFORMACIÓN MÉDICA ====================

# ==================== HELPER FUNCTIONS FOR MEDICAL DATA EXTRACTION ====================

def _extract_text_from_file(file_path: str) -> str:
    """Extrae texto de PDF/OCR"""
    text = ""
    
    if file_path.lower().endswith('.pdf'):
        try:
            import PyPDF2
            with open(file_path, 'rb') as pdf_file:
                reader = PyPDF2.PdfReader(pdf_file)
                for page in reader.pages:
                    text += page.extract_text() + "\n"
        except Exception as e:
            logger.warning(f"No se pudo extraer PDF: {e}")
    else:
        try:
            import pytesseract
            image = Image.open(file_path)
            text = pytesseract.image_to_string(image)
        except Exception as e:
            logger.warning(f"OCR failed: {e}")
    
    return text


def _extract_physician_info(text: str) -> tuple:
    """Extrae médico, especialidad y cédula"""
    physician = None
    specialty = None
    physician_id = None
    text_lower = text.lower()
    
    # Buscar nombre del médico
    physician_patterns = [
        r'(?:médico\s+responsable|médico\s+tratante|dr\.?\s+|doctor\s+|prof(?:esional)?\.?\s+)([a-záéíóú\s]{6,})(?:\s+[a-záéíóú]{3,})?(?:\n|,|\s+(?:rut|cédula))',
        r'(?:atendido\s+por|atiende|firmado\s+por)\s*[:?\-]?\s*([a-záéíóú\s]{6,})(?:\n|,)',
    ]
    
    for pattern in physician_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE | re.MULTILINE)
        if matches:
            physician = matches[0].strip().title()
            break
    
    # Buscar especialidad
    specialty_keywords = {
        'medicina general': ['medicina general', 'médico general'],
        'pediatría': ['pediatría', 'pediatra'],
        'cardiología': ['cardiología', 'cardiólogo'],
        'neurología': ['neurología', 'neurólogo'],
        'dermatología': ['dermatología', 'dermatólogo'],
        'ginecología': ['ginecología', 'ginecólogo'],
        ESPECIALIDAD_OFTALMOLOGIA: ['oftalmología', 'oftalmólogo'],
        'oncología': ['oncología', 'oncólogo'],
    }
    
    for spec, keywords in specialty_keywords.items():
        if any(kw in text_lower for kw in keywords):
            specialty = spec
            break
    
    # Buscar cédula
    id_patterns = [
        r'(?:médico|dr|doctor)[^\n]*?(?:rut|cédula|id)[:\s\-]*([0-9]{1,2}\.[0-9]{3}\.[0-9]{3}[0-9k\-]?)',
    ]
    
    for pattern in id_patterns:
        id_match = re.search(pattern, text, re.IGNORECASE)
        if id_match:
            physician_id = id_match.group(1).strip()
            break
    
    return physician, specialty, physician_id


def _extract_institution(text: str) -> str:
    """Extrae institución/clínica"""
    institution_patterns = [
        r'(?:clínica|hospital|centro|consultorio)\s+([a-záéíóú0-9\s\-\.]+?)(?:\n|,)',
    ]
    
    for pattern in institution_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        if matches:
            return matches[0].strip().title()
    
    return None


def _extract_date(text: str) -> str:
    """Extrae fecha del documento"""
    date_patterns = [
        r'(?:fecha\s+(?:de\s+)?(?:atención|consulta|documento))\s*[:|\-]?\s*(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})',
        r'(?:fecha|date)\s*[:|\-]?\s*(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})',
    ]
    
    for pattern in date_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        if matches:
            return matches[0].strip()
    
    return None


def _extract_diagnosis(text: str) -> list:
    """Extrae diagnósticos"""
    diagnosis = []
    keywords = ['diagnóstico', 'diagnóstco', 'dx', 'diagnosis', 'impresión clínica']
    
    lines = text.split('\n')
    for i, line in enumerate(lines):
        if any(kw in line.lower() for kw in keywords):
            if i + 1 < len(lines):
                diag_text = lines[i + 1].strip()
                if diag_text and len(diag_text) > 5:
                    diagnosis.append(diag_text)
    
    return diagnosis


def _extract_medications(text: str) -> tuple:
    """Extrae medicamentos y sus detalles"""
    medications = []
    medication_data = []
    text_lower = text.lower()
    
    common_meds = [
        'paracetamol', 'ibuprofeno', 'aspirina', 'amoxicilina', 'omeprazol',
        'sertralina', 'fluoxetina', 'metformina', 'insulina', 'prednisona'
    ]
    
    for med in common_meds:
        if med.lower() in text_lower:
            medications.append(med.capitalize())
            
            # Intentar extraer dosis
            dosage_match = re.search(rf'\b{med}\s+(\d+(?:[,\.]\d+)?)\s*(?:mg|ml)', text, re.IGNORECASE)
            if dosage_match:
                medication_data.append({
                    'nombre': med.capitalize(),
                    'dosis': f"{dosage_match.group(1)} mg",
                    'indicaciones': 'Según prescripción',
                })
    
    return list(set(medications)), medication_data


def _extract_findings(text: str) -> list:
    """Extrae hallazgos clínicos"""
    findings = []
    text_lower = text.lower()
    
    finding_map = {
        'normal': ['normal', 'sin particularidades'],
        'presión alta': ['hipertensión', 'presión elevada'],
        'glucosa elevada': ['glucosa alta', 'diabetes'],
        'anemia': ['hemoglobina baja'],
        'infección': ['infección', 'bacteria'],
    }
    
    for finding, keywords in finding_map.items():
        if any(kw in text_lower for kw in keywords):
            findings.append(finding)
    
    return findings


def _detect_document_type(text: str) -> str:
    """Detecta tipo de documento"""
    text_lower = text.lower()
    
    if any(w in text_lower for w in ['receta', 'medicamento']):
        return 'Receta Médica'
    elif any(w in text_lower for w in ['laboratorio', 'análisis', 'resultado']):
        return 'Reporte de Laboratorio'
    elif any(w in text_lower for w in ['radiografía', 'ecografía']):
        return 'Imagen Diagnóstica'
    elif any(w in text_lower for w in ['oftalmología', 'visión']):
        return 'Reporte Oftalmológico'
    
    return 'Documento Médico'


# ==================== REFACTORED MAIN FUNCTION ====================

def extract_medical_findings(file_path: str) -> Dict:
    """
    Extrae información médica COMPLETA del documento
    VERSIÓN REFACTORIZADA - Complejidad reducida mediante funciones auxiliares
    
    Returns:
        Dict con todos los campos extraídos
    """
    import re
    
    try:
        # Paso 1: Extraer texto
        text = _extract_text_from_file(file_path)
        
        if not text.strip():
            return {
                'status': 'no_text',
                'message': 'No se pudo extraer texto del documento',
                'document_type': 'unknown',
                'physician': None,
                'specialty': None,
                'institution': None,
                'date': None,
                'diagnosis': [],
                'medications': [],
                'findings': [],
            }
        
        # Paso 2: Extraer datos individuales (cada función es simple y enfocada)
        physician, specialty, physician_id = _extract_physician_info(text)
        institution = _extract_institution(text)
        date = _extract_date(text)
        diagnosis = _extract_diagnosis(text)
        medications, medication_data = _extract_medications(text)
        findings = _extract_findings(text)
        document_type = _detect_document_type(text)
        
        # Paso 3: Compilar respuesta
        return {
            'status': 'success',
            'document_type': document_type,
            'physician': physician,
            'specialty': specialty,
            'physician_id': physician_id,
            'institution': institution,
            'date': date,
            'diagnosis': diagnosis[:5],
            'medications': medications,
            'medication_details': medication_data[:10],
            'findings': findings[:10],
            'extracted_text': text[:300] if len(text) > 300 else text,
            'text_length': len(text),
        }
    
    except Exception as e:
        logger.error(f"Error extrayendo información médica: {str(e)}")
        return {
            'status': 'error',
            'message': str(e),
            'document_type': 'unknown',
        }


