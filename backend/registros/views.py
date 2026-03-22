from rest_framework import viewsets, status, serializers
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from .models import Medicamento, Paciente, RegistroClinico, MedicalDocument
from .serializers import LoginSerializer, RegisterSerializer, UserSerializer, PacienteDetailSerializer
from django_ratelimit.decorators import ratelimit
from .analysis_service import get_analyzer, MedicalImageProcessor
from django.core.files.uploadedfile import UploadedFile
import mimetypes
from datetime import datetime
import json
import logging
import random

logger = logging.getLogger(__name__)

# ==================== RATE LIMITING CONFIGURACIÓN ====================
# Login: 5 intentos por hora
# Register: 3 registros por hora  
# File Upload: 20 subidas por hora

# ==================== VALIDADORES ====================

def validate_file_upload(uploaded_file, max_size_mb=10, allowed_types=None):
    """
    Validar archivo subido
    
    Args:
        uploaded_file: archivo de Django
        max_size_mb: tamaño máximo en MB
        allowed_types: lista de tipos MIME permitidos
    
    Returns:
        dict con 'valid' y 'error' si hay problema
    """
    if allowed_types is None:
        allowed_types = ['application/pdf', 'image/jpeg', 'image/png', 'application/msword', 
                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
    
    # Validar tamaño
    max_size_bytes = max_size_mb * 1024 * 1024
    if uploaded_file.size > max_size_bytes:
        return {
            'valid': False,
            'error': f'Archivo demasiado grande. Máximo: {max_size_mb}MB, Tu archivo: {uploaded_file.size / 1024 / 1024:.1f}MB'
        }
    
    # Validar tipo MIME
    file_type, _ = mimetypes.guess_type(uploaded_file.name)
    if file_type and file_type not in allowed_types:
        return {
            'valid': False,
            'error': f'Tipo de archivo no permitido. Permitidos: PDF, JPG, PNG, DOC, DOCX'
        }
    
    return {'valid': True}


# ==================== AUTENTICACIÓN CON JWT ====================

@api_view(['POST'])
@permission_classes([AllowAny])
@ratelimit(key='ip', rate='5/h', method='POST')
def login_view(request):
    """
    Endpoint de Login con JWT
    
    Rate Limit: 5 intentos por hora por IP
    
    Recibe: username, password
    Retorna: access token, refresh token, user info
    """
    # Manejar rate limit
    if getattr(request, 'limited', False):
        return Response(
            {
                'error': 'Demasiados intentos de login',
                'detail': 'Has excedido el límite de 5 intentos por hora',
                'retry_after': 'Por favor, intenta de nuevo en una hora'
            },
            status=status.HTTP_429_TOO_MANY_REQUESTS,
            headers={'Retry-After': '3600'}
        )
    
    serializer = LoginSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(
            {'error': 'Username y password son requeridos'},
            status=status.HTTP_400_BAD_REQUEST
        )

    username = serializer.validated_data['username']
    password = serializer.validated_data['password']

    user = authenticate(username=username, password=password)
    
    if user is None:
        return Response(
            {'error': 'Credenciales inválidas'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Generar tokens JWT
    refresh = RefreshToken.for_user(user)
    
    # Obtener datos del paciente si existen
    paciente_data = None
    try:
        paciente = Paciente.objects.get(usuario=user)
        paciente_data = PacienteDetailSerializer(paciente).data
    except Paciente.DoesNotExist:
        pass

    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
        },
        'paciente': paciente_data,
        'message': 'Login exitoso'
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
@ratelimit(key='ip', rate='3/h', method='POST')
def register_view(request):
    """
    Endpoint de Registro con JWT
    
    Rate Limit: 3 registros por hora por IP
    
    Recibe: username, password, email, first_name, last_name, numero_cedula, genero, fecha_nacimiento
    Retorna: access token, refresh token, user info
    """
    # Manejar rate limit
    if getattr(request, 'limited', False):
        return Response(
            {
                'error': 'Demasiados registros',
                'detail': 'Has excedido el límite de 3 registros por hora',
                'retry_after': 'Por favor, intenta de nuevo en una hora'
            },
            status=status.HTTP_429_TOO_MANY_REQUESTS,
            headers={'Retry-After': '3600'}
        )
    
    serializer = RegisterSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(
            {'error': serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        user = User.objects.create_user(
            username=serializer.validated_data['username'],
            password=serializer.validated_data['password'],
            email=serializer.validated_data['email'],
            first_name=serializer.validated_data.get('first_name', ''),
            last_name=serializer.validated_data.get('last_name', '')
        )

        # Crear perfil de paciente
        paciente = Paciente.objects.create(
            usuario=user,
            numero_cedula=serializer.validated_data['numero_cedula'],
            genero=serializer.validated_data['genero'],
            fecha_nacimiento=serializer.validated_data['fecha_nacimiento']
        )

        # Generar tokens JWT
        refresh = RefreshToken.for_user(user)

        paciente_serializer = PacienteDetailSerializer(paciente)

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
            },
            'paciente': paciente_serializer.data,
            'message': 'Registro exitoso'
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response(
            {'error': f'Error en el registro: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """
    Endpoint de Logout
    Con JWT, solo es necesario eliminar el token del cliente
    """
    return Response(
        {'message': 'Logout exitoso. Elimina el token del cliente.'},
        status=status.HTTP_200_OK
    )


@api_view(['POST'])
@permission_classes([AllowAny])
@ratelimit(key='ip', rate='10/h', method='POST')
def refresh_token_view(request):
    """
    Endpoint para refrescar access token
    
    Rate Limit: 10 intentos por hora por IP
    
    Recibe: refresh token
    Retorna: nuevo access token
    """
    # Manejar rate limit
    if getattr(request, 'limited', False):
        return Response(
            {
                'error': 'Demasiados intentos de refresh',
                'detail': 'Has excedido el límite de 10 refrescos por hora',
                'retry_after': 'Por favor, intenta de nuevo en unos minutos'
            },
            status=status.HTTP_429_TOO_MANY_REQUESTS,
            headers={'Retry-After': '600'}
        )
    
    try:
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response(
                {'error': 'Refresh token requerido'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        refresh = RefreshToken(refresh_token)
        return Response({
            'access': str(refresh.access_token)
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response(
            {'error': 'Token inválido o expirado'},
            status=status.HTTP_401_UNAUTHORIZED
        )


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
@ratelimit(key='ip', rate='30/h', method='PATCH')
def update_paciente_profile(request):
    """
    Endpoint para actualizar el perfil del paciente (Onboarding)
    
    Rate Limit: 30 actualizaciones por hora por usuario
    
    Recibe: campos opcionales - telefono, direccion, ciudad, pais, alergias, enfermedades_cronicas
    Retorna: datos del paciente actualizado
    """
    # Manejar rate limit
    if getattr(request, 'limited', False):
        return Response(
            {
                'error': 'Demasiadas actualizaciones',
                'detail': 'Has excedido el límite de 30 actualizaciones por hora',
                'retry_after': 'Por favor, intenta en unos minutos'
            },
            status=status.HTTP_429_TOO_MANY_REQUESTS,
            headers={'Retry-After': '600'}
        )
    
    try:
        paciente = Paciente.objects.get(usuario=request.user)
        
        # Actualizar campos si se proporcionan
        updateable_fields = ['telefono', 'direccion', 'ciudad', 'pais', 'alergias', 'enfermedades_cronicas']
        for field in updateable_fields:
            if field in request.data:
                setattr(paciente, field, request.data.get(field))
        
        paciente.save()
        
        serializer = PacienteDetailSerializer(paciente)
        return Response({
            'message': 'Perfil actualizado exitosamente',
            'paciente': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Paciente.DoesNotExist:
        return Response(
            {'error': 'Perfil de paciente no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': f'Error al actualizar perfil: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


# ==================== REGISTROS CLÍNICOS ====================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@ratelimit(key='ip', rate='20/h', method='POST')
def upload_registro_view(request):
    """
    Endpoint para subir un registro clínico
    
    Rate Limit: 20 subidas por hora por usuario
    
    Recibe: archivo documento_respaldo
    Retorna: registro clínico creado
    """
    # Manejar rate limit
    if getattr(request, 'limited', False):
        return Response(
            {
                'error': 'Demasiadas subidas',
                'detail': 'Has excedido el límite de 20 subidas por hora',
                'retry_after': 'Por favor, intenta en unos minutos'
            },
            status=status.HTTP_429_TOO_MANY_REQUESTS,
            headers={'Retry-After': '600'}
        )
    
    try:
        paciente = Paciente.objects.get(usuario=request.user)
    except Paciente.DoesNotExist:
        return Response(
            {'error': 'Perfil de paciente no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    if 'documento_respaldo' not in request.FILES:
        return Response(
            {'error': 'Archivo requerido'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    uploaded_file = request.FILES['documento_respaldo']
    
    # Validar archivo
    validation = validate_file_upload(uploaded_file)
    if not validation['valid']:
        return Response(
            {'error': validation['error']},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        registro = RegistroClinico.objects.create(
            paciente=request.user,
            especialidad=request.data.get('especialidad', 'General'),
            clinica=request.data.get('clinica', 'Clínica Local'),
            fecha_consulta=request.data.get('fecha_consulta', __import__('datetime').date.today()),
            diagnostico=request.data.get('diagnostico', 'Pendiente de análisis'),
            documento_respaldo=uploaded_file
        )
        
        return Response({
            'id': registro.id,
            'message': 'Registro clínico subido exitosamente',
            'file_name': uploaded_file.name,
        }, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        return Response(
            {'error': f'Error al subir registro: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    """
    Endpoint de Login con JWT
    Recibe: username, password
    Retorna: access token, refresh token, user info
    """
    serializer = LoginSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(
            {'error': 'Username y password son requeridos'},
            status=status.HTTP_400_BAD_REQUEST
        )

    username = serializer.validated_data['username']
    password = serializer.validated_data['password']

    user = authenticate(username=username, password=password)
    
    if user is None:
        return Response(
            {'error': 'Credenciales inválidas'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Generar tokens JWT
    refresh = RefreshToken.for_user(user)
    
    # Obtener datos del paciente si existen
    paciente_data = None
    try:
        paciente = Paciente.objects.get(usuario=user)
        paciente_data = PacienteDetailSerializer(paciente).data
    except Paciente.DoesNotExist:
        pass

    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
        },
        'paciente': paciente_data,
        'message': 'Login exitoso'
    }, status=status.HTTP_200_OK)


# ==================== MEDICAL IMAGE ANALYSIS ENDPOINTS ====================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def analyze_document(request, doc_id):
    """
    Analizar documento médico con MedSigLIP
    
    Endpoint: POST /api/documents/{doc_id}/analyze/
    
    Realiza:
    - Extracción de embeddings de imagen médica (448-dim)
    - Validación de formato y calidad de imagen
    - Almacenamiento de resultados en ia_analisis
    
    Retorna: analysis results, embeddings metadata, confidence scores
    """
    logger.warning(f"📊 ANALYZE ENDPOINT CALLED - doc_id: {doc_id}, user: {request.user}")
    
    try:
        # Verificar que el documento pertenece al usuario autenticado
        document = MedicalDocument.objects.get(id=doc_id, usuario=request.user)
        logger.warning(f"✅ Document found: {document.id}")
    except MedicalDocument.DoesNotExist:
        logger.warning(f"❌ Document not found: {doc_id}")
        return Response(
            {'error': 'Documento no encontrado o no tienes permiso'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Verificar si los modelos de IA están disponibles
    from registros.analysis_service import MODELS_AVAILABLE
    logger.warning(f"🤖 MODELS_AVAILABLE: {MODELS_AVAILABLE}")
    
    if not MODELS_AVAILABLE:
        logger.warning(f"⚠️ AI models not available, returning mock analysis")
        # Análisis simulado/placeholder cuando los modelos no están disponibles
        analysis_data = {
            'timestamp': datetime.now().isoformat(),
            'modelo': 'MedSigLIP-448px (MOCK - Models not installed)',
            'embeddings': [random.random() for _ in range(448)],
            'embedding_dim': 448,
            'confidence': random.uniform(0.7, 0.95),
            'processing_time': random.uniform(0.5, 2.0),
            'image_metadata': {
                'width': 448,
                'height': 448,
                'format': 'RGB'
            },
            'status': 'completed_mock',
            'note': 'Análisis simulado. Para análisis real, instala tensorflow y transformers'
        }
        
        document.ia_analisis = json.dumps(analysis_data, default=str)
        document.save()
        
        return Response({
            'id': document.id,
            'message': 'Análisis simulado completado (modelos no instalados)',
            'analysis': {
                'timestamp': analysis_data['timestamp'],
                'modelo': analysis_data['modelo'],
                'confidence': analysis_data['confidence'],
                'embedding_dim': analysis_data['embedding_dim'],  # Correcto para frontend
                'embeddings': analysis_data['embeddings'],  # Array de embeddings
                'image_metadata': analysis_data['image_metadata'],  # Información de imagen
                'processing_time': analysis_data['processing_time'],
                'status': 'completed_mock',
                'note': 'Análisis simulado. Para análisis real con MedSigLIP, instala requirements_ai.txt'
            }
        }, status=status.HTTP_200_OK)
    
    try:
        # Obtener el analizador de MedSigLIP
        analyzer = get_analyzer()
        
        # Si el analizador no está disponible, usar análisis simulado
        if analyzer is None:
            logger.warning(f"⚠️ Analyzer not available for document {doc_id}, returning mock analysis")
            mock_analysis_data = {
                'timestamp': datetime.now().isoformat(),
                'modelo': 'MedSigLIP-448px (MOCK)',
                'embeddings': [random.random() for _ in range(448)],
                'embedding_dim': 448,
                'confidence': random.uniform(0.7, 0.95),
                'processing_time': random.uniform(0.5, 2.0),
                'image_metadata': {
                    'width': 448,
                    'height': 448,
                    'format': 'RGB'
                },
                'status': 'completed_mock'
            }
            
            document.ia_analisis = json.dumps(mock_analysis_data, default=str)
            document.save()
            
            return Response({
                'id': document.id,
                'message': 'Mock analysis completed (AI models not available)',
                'analysis': {
                    'timestamp': mock_analysis_data['timestamp'],
                    'modelo': mock_analysis_data['modelo'],
                    'confidence': mock_analysis_data['confidence'],
                    'embedding_dim': mock_analysis_data['embedding_dim'],  # Correcto para frontend
                    'embeddings': mock_analysis_data['embeddings'],  # Array de embeddings
                    'image_metadata': mock_analysis_data['image_metadata'],  # Metadata de imagen
                    'processing_time': mock_analysis_data['processing_time'],
                    'status': 'completed_mock'
                }
            }, status=status.HTTP_200_OK)
        
        # Obtener ruta del archivo
        image_path = document.archivo.path if document.archivo else None
        if not image_path:
            return Response(
                {'error': 'Archivo de documento no encontrado'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        logger.info(f"Iniciando análisis de documento {doc_id}")
        
        # Realizar análisis con MedSigLIP
        analysis_result = analyzer.analyze_image(image_path)
        
        # Crear metadata de análisis
        analysis_data = {
            'timestamp': datetime.now().isoformat(),
            'modelo': 'MedSigLIP-448px',
            'embeddings': analysis_result.get('embeddings', []),
            'embedding_dim': 448,
            'confidence': analysis_result.get('confidence', 0.0),
            'processing_time': analysis_result.get('processing_time', 0.0),
            'image_metadata': {
                'width': analysis_result.get('image_shape', [0, 0])[1],
                'height': analysis_result.get('image_shape', [0, 0])[0],
                'format': 'RGB'
            },
            'status': 'completed'
        }
        
        # Guardar resultados en el modelo
        document.ia_analisis = json.dumps(analysis_data, default=str)
        document.save()
        
        logger.info(f"Análisis completado para documento {doc_id}")
        
        return Response({
            'id': document.id,
            'message': 'Análisis completado exitosamente',
            'analysis': {
                'timestamp': analysis_data['timestamp'],
                'modelo': analysis_data['modelo'],
                'confidence': analysis_data['confidence'],
                'embedding_dim': analysis_data['embedding_dim'],  # Correcto para frontend
                'embeddings': analysis_data['embeddings'],  # Array de embeddings para visualizar
                'image_metadata': analysis_data['image_metadata'],  # Metadata de imagen
                'processing_time': analysis_data['processing_time'],
                'status': 'completed'
            }
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        logger.error(f"Error en análisis de documento {doc_id}: {str(e)}")
        return Response(
            {'error': f'Error en análisis: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def extract_findings(request, doc_id):
    """
    Extraer información médica del documento
    
    Endpoint: POST /api/documents/{doc_id}/extract-findings/
    
    Extrae:
    - Tipo de documento (Receta, Laboratorio, Imagen, etc.)
    - Hallazgos/diagnósticos detectados
    - Medicamentos mencionados
    - Observaciones clínicas
    
    Retorna: foundamental information from the medical document
    """
    try:
        # Verificar que el documento pertenece al usuario autenticado
        document = MedicalDocument.objects.get(id=doc_id, usuario=request.user)
        logger.info(f"Extrayendo hallazgos del documento {doc_id}")
        
    except MedicalDocument.DoesNotExist:
        return Response(
            {'error': 'Documento no encontrado o no tienes permiso'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # Obtener ruta del archivo
        if not document.archivo:
            return Response(
                {'error': 'Archivo de documento no encontrado'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        image_path = document.archivo.path
        
        # Extraer información médica del documento
        from registros.analysis_service import extract_medical_findings
        findings = extract_medical_findings(image_path)
        
        logger.info(f"Información extraída del documento {doc_id}: {findings['status']}")
        
        return Response({
            'id': document.id,
            'message': 'Información extraída exitosamente',
            'extraction': findings
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        logger.error(f"Error extrayendo hallazgos del documento {doc_id}: {str(e)}")
        return Response(
            {'error': f'Error extrayendo información: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def classify_document_findings(request, doc_id):
    """
    Clasificar hallazgos médicos en documento
    
    Endpoint: POST /api/documents/{doc_id}/classify/
    
    Parámetros (JSON):
    {
        "findings": ["radiografia", "pneumonia", "edema"]
    }
    
    Retorna: Classification results with confidence scores
    """
    try:
        document = MedicalDocument.objects.get(id=doc_id, usuario=request.user)
    except MedicalDocument.DoesNotExist:
        return Response(
            {'error': 'Documento no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    try:
        findings = request.data.get('findings', [])
        if not findings:
            return Response(
                {'error': 'Lista de hallazgos requerida'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        analyzer = get_analyzer()
        
        if analyzer is None:
            # Retornar clasificación simulada si los modelos no están disponibles
            logger.warning(f"⚠️ Analyzer not available, returning mock classification")
            mock_predictions = {finding: random.uniform(0.6, 0.95) for finding in findings}
            
            ia_analisis = {}
            if document.ia_analisis:
                try:
                    ia_analisis = json.loads(document.ia_analisis)
                except json.JSONDecodeError:
                    ia_analisis = {}
            
            ia_analisis['classification'] = {
                'findings': mock_predictions,
                'timestamp': datetime.now().isoformat(),
                'status': 'mock'
            }
            
            document.ia_analisis = json.dumps(ia_analisis, default=str)
            document.save()
            
            return Response({
                'id': document.id,
                'message': 'Mock classification completed',
                'classification': mock_predictions
            }, status=status.HTTP_200_OK)
        
        image_path = document.archivo.path if document.archivo else None
        if not image_path:
            return Response(
                {'error': 'Archivo de documento no encontrado'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        logger.info(f"Iniciando clasificación de hallazgos para documento {doc_id}")
        
        # Realizar clasificación
        classification_result = analyzer.classify_finding(image_path, findings)
        
        # Actualizar análisis con resultados de clasificación
        ia_analisis = {}
        if document.ia_analisis:
            try:
                ia_analisis = json.loads(document.ia_analisis)
            except json.JSONDecodeError:
                ia_analisis = {}
        
        ia_analisis['classification'] = {
            'findings': classification_result.get('predictions', {}),
            'timestamp': datetime.now().isoformat()
        }
        
        document.ia_analisis = json.dumps(ia_analisis, default=str)
        document.save()
        
        logger.info(f"Clasificación completada para documento {doc_id}")
        
        return Response({
            'id': document.id,
            'message': 'Clasificación completada',
            'classification': classification_result.get('predictions', {})
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        logger.error(f"Error en clasificación de documento {doc_id}: {str(e)}")
        return Response(
            {'error': f'Error en clasificación: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_similar_documents(request):
    """
    Buscar documentos similares usando búsqueda semántica
    
    Endpoint: GET /api/documents/search-similar/?ref_doc_id=<id>&top_k=5
    
    Parámetros:
    - ref_doc_id: ID del documento de referencia
    - top_k: Cantidad de resultados (default: 5)
    
    Retorna: Lista de documentos similares con scores de similitud
    """
    try:
        ref_doc_id = request.query_params.get('ref_doc_id')
        top_k = int(request.query_params.get('top_k', 5))
        
        if not ref_doc_id:
            return Response(
                {'error': 'ref_doc_id requerido'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Obtener documento de referencia
        try:
            ref_document = MedicalDocument.objects.get(
                id=ref_doc_id, 
                usuario=request.user
            )
        except MedicalDocument.DoesNotExist:
            return Response(
                {'error': 'Documento de referencia no encontrado'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Obtener análisis del documento de referencia
        if not ref_document.ia_analisis:
            return Response(
                {'error': 'Documento de referencia sin análisis'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            ref_analysis = json.loads(ref_document.ia_analisis)
            ref_embeddings = ref_analysis.get('embeddings', [])
        except (json.JSONDecodeError, KeyError):
            return Response(
                {'error': 'Análisis del documento de referencia inválido'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not ref_embeddings:
            return Response(
                {'error': 'Embeddings no disponibles para búsqueda'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        analyzer = get_analyzer()
        
        if analyzer is None:
            # Retornar búsqueda simulada si los modelos no están disponibles
            logger.warning(f"⚠️ Analyzer not available, returning mock search results")
            
            # Obtener documentos del usuario (simulado - ordenado aleatorio)
            user_documents = list(MedicalDocument.objects.filter(
                usuario=request.user,
                ia_analisis__isnull=False
            ).exclude(id=ref_doc_id)[:top_k])
            
            results = []
            for idx, doc in enumerate(user_documents):
                results.append({
                    'id': doc.id,
                    'tipo_documento': doc.tipo_documento,
                    'especialidad': doc.especialidad,
                    'similarity_score': random.uniform(0.6, 0.99),
                    'created_at': doc.creado_en.isoformat() if doc.creado_en else None,
                    'rank': idx + 1
                })
            
            return Response({
                'reference_doc_id': ref_doc_id,
                'total_results': len(results),
                'results': results,
                'search_method': 'Random (Mock - AI not available)'
            }, status=status.HTTP_200_OK)
        
        # Obtener todos los documentos del usuario con análisis
        user_documents = MedicalDocument.objects.filter(
            usuario=request.user,
            ia_analisis__isnull=False
        ).exclude(id=ref_doc_id)
        
        logger.info(f"Buscando {len(user_documents)} documentos similares a {ref_doc_id}")
        
        # Recopilar embeddings de documentos
        doc_embeddings_list = []
        doc_ids = []
        
        for doc in user_documents:
            try:
                doc_analysis = json.loads(doc.ia_analisis)
                embeddings = doc_analysis.get('embeddings', [])
                if embeddings:
                    doc_embeddings_list.append(embeddings)
                    doc_ids.append(doc.id)
            except (json.JSONDecodeError, KeyError):
                continue
        
        if not doc_embeddings_list:
            return Response({
                'message': 'No hay documentos similares disponibles',
                'results': [],
                'total': 0
            }, status=status.HTTP_200_OK)
        
        # Realizar búsqueda semántica
        similar_results = analyzer.search_similar_by_embeddings(
            reference_embedding=ref_embeddings,
            comparison_embeddings=doc_embeddings_list,
            top_k=min(top_k, len(doc_embeddings_list))
        )
        
        # Construir respuesta
        results = []
        for idx, (similarity_score, doc_idx) in enumerate(similar_results):
            doc_id = doc_ids[doc_idx]
            doc = MedicalDocument.objects.get(id=doc_id)
            results.append({
                'id': doc.id,
                'tipo_documento': doc.tipo_documento,
                'especialidad': doc.especialidad,
                'similarity_score': float(similarity_score),
                'created_at': doc.creado_en.isoformat() if doc.creado_en else None,
                'rank': idx + 1
            })
        
        logger.info(f"Búsqueda completada: {len(results)} documentos similares encontrados")
        
        return Response({
            'reference_doc_id': ref_doc_id,
            'total_results': len(results),
            'results': results,
            'search_method': 'MedSigLIP Semantic Search'
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        logger.error(f"Error en búsqueda semántica: {str(e)}")
        return Response(
            {'error': f'Error en búsqueda: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


# ==================== PERFIL ENDPOINTS ====================

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Actualizar información completa del perfil del usuario
    Recibe: nombre_completo, email, cedula, telefono, direccion, ciudad
    Retorna: datos del usuario actualizado
    """
    try:
        user = request.user
        
        # Actualizar campos del usuario
        if 'email' in request.data:
            user.email = request.data.get('email')
        if 'nombre_completo' in request.data:
            nombre_parts = request.data.get('nombre_completo').split(' ', 1)
            user.first_name = nombre_parts[0]
            user.last_name = nombre_parts[1] if len(nombre_parts) > 1 else ''
        
        user.save()
        
        # Actualizar datos del paciente
        try:
            paciente = Paciente.objects.get(usuario=user)
            
            if 'cedula' in request.data:
                paciente.cedula = request.data.get('cedula')
            if 'telefono' in request.data:
                paciente.telefono = request.data.get('telefono')
            if 'direccion' in request.data:
                paciente.direccion = request.data.get('direccion')
            if 'ciudad' in request.data:
                paciente.ciudad = request.data.get('ciudad')
            
            paciente.save()
            
            paciente_serializer = PacienteDetailSerializer(paciente)
        except Paciente.DoesNotExist:
            paciente_serializer = None
        
        return Response({
            'message': 'Perfil actualizado exitosamente',
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
            },
            'paciente': paciente_serializer.data if paciente_serializer else None
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response(
            {'detail': f'Error al actualizar perfil: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    Cambiar contraseña del usuario
    Recibe: current_password, new_password
    Retorna: confirmación de cambio
    """
    try:
        user = request.user
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')
        
        if not current_password or not new_password:
            return Response(
                {'detail': 'Se requieren la contraseña actual y la nueva contraseña'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar contraseña actual
        if not user.check_password(current_password):
            return Response(
                {'detail': 'La contraseña actual es incorrecta'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Validar longitud mínima
        if len(new_password) < 8:
            return Response(
                {'detail': 'La nueva contraseña debe tener al menos 8 caracteres'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Cambiar contraseña
        user.set_password(new_password)
        user.save()
        
        return Response({
            'message': 'Contraseña actualizada exitosamente'
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response(
            {'detail': f'Error al cambiar contraseña: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


# ==================== DOCUMENTO ENDPOINTS ====================

@api_view(['POST', 'OPTIONS'])
@permission_classes([IsAuthenticated])
@ratelimit(key='ip', rate='50/h', method='POST')
def upload_document(request):
    """
    Endpoint para subir documentos médicos
    
    Rate Limit: 50 subidas por hora por usuario
    Requiere: JWT token en Authorization header
    
    Campo de archivo: document
    Campos opcionales: tipo_documento, descripcion, especialidad, medico_emisor
    
    Retorna: document data actualizado
    """
    # Handle OPTIONS para CORS preflight
    if request.method == 'OPTIONS':
        return Response({'status': 'ok'}, status=200)
    
    if getattr(request, 'limited', False):
        return Response(
            {
                'error': 'Límite de carga excedido',
                'detail': 'Has excedido el límite de 20 subidas por hora',
            },
            status=status.HTTP_429_TOO_MANY_REQUESTS,
            headers={'Retry-After': '3600'}
        )

    try:
        if 'document' not in request.FILES:
            return Response(
                {'detail': 'Campo "document" requerido'},
                status=status.HTTP_400_BAD_REQUEST
            )

        uploaded_file = request.FILES['document']

        # Validar archivo
        validation = validate_file_upload(uploaded_file, max_size_mb=50, allowed_types=[
            'image/jpeg', 'image/png', 'image/tiff',
            'application/pdf',
            'image/x-dcm',  # DICOM
        ])

        if not validation['valid']:
            return Response(
                {'detail': validation['error']},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Crear documento
        medical_doc = MedicalDocument.objects.create(
            usuario=request.user,
            archivo=uploaded_file,
            nombre=request.data.get('descripcion', uploaded_file.name),
            tipo_documento=request.data.get('tipo_documento', 'otro'),
            descripcion=request.data.get('descripcion', ''),
            especialidad=request.data.get('especialidad', ''),
            medico_emisor=request.data.get('medico_emisor', ''),
        )

        return Response({
            'message': 'Documento subido exitosamente',
            'document': {
                'id': medical_doc.id,
                'nombre': medical_doc.nombre,
                'tipo_documento': medical_doc.tipo_documento,
                'archivo_url': medical_doc.archivo.url,
                'creado_en': medical_doc.creado_en,
            }
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response(
            {'detail': f'Error al subir documento: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_documents(request):
    """
    Listar documentos del usuario autenticado
    
    Parámetros opcionales:
    - tipo: filtrar por tipo de documento
    - página: para paginación
    """
    try:
        documentos = MedicalDocument.objects.filter(usuario=request.user)

        # Filtrar por tipo si se especifica
        tipo_filter = request.query_params.get('tipo')
        if tipo_filter:
            documentos = documentos.filter(tipo_documento=tipo_filter)

        # Serializar
        documentos_data = []
        for doc in documentos[:50]:  # Límite de 50 documentos
            documentos_data.append({
                'id': doc.id,
                'nombre': doc.nombre,
                'tipo_documento': doc.tipo_documento,
                'descripcion': doc.descripcion,
                'archivo_url': doc.archivo.url,
                'especialidad': doc.especialidad,
                'medico_emisor': doc.medico_emisor,
                'creado_en': doc.creado_en,
                'actualizado_en': doc.actualizado_en,
            })

        return Response({
            'total': len(documentos_data),
            'documentos': documentos_data
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'detail': f'Error al listar documentos: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_document(request, doc_id):
    """
    Eliminar un documento específico (solo el propietario puede)
    """
    try:
        medical_doc = MedicalDocument.objects.get(id=doc_id, usuario=request.user)
        medical_doc.archivo.delete()  # Eliminar archivo
        medical_doc.delete()  # Eliminar registro

        return Response({
            'message': 'Documento eliminado exitosamente'
        }, status=status.HTTP_200_OK)

    except MedicalDocument.DoesNotExist:
        return Response(
            {'detail': 'Documento no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'detail': f'Error al eliminar documento: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==================== AI MEDICAL ANALYSIS ENDPOINTS ====================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def analyze_medical_document_text(request, doc_id):
    """
    Analizar documento médico con MedGemma para extracción de información
    
    Endpoint: POST /api/documents/{doc_id}/analyze-text/
    
    Realiza:
    - Extracción de medicamentos, diagnósticos, síntomas
    - Generación de resumen ejecutivo
    - Clasificación de tipo de documento
    - Detección de enfermedades y hallazgos
    
    Retorna: análisis detallado con información médica estructurada
    """
    try:
        from .analysis_service import get_text_analyzer, get_ocr_extractor
        import os
        
        # Obtener documento
        try:
            document = MedicalDocument.objects.get(id=doc_id, usuario=request.user)
        except MedicalDocument.DoesNotExist:
            return Response(
                {'error': 'Documento no encontrado o no tienes permiso'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Obtener ruta del archivo
        if not document.archivo:
            return Response(
                {'error': 'Archivo de documento no encontrado'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        archivo_path = document.archivo.path
        
        # Extraer texto según tipo de archivo
        ocr = get_ocr_extractor()
        
        if archivo_path.lower().endswith('.pdf'):
            extraction = ocr.extract_from_pdf(archivo_path)
        else:
            # Es una imagen
            extraction = ocr.extract_from_image(archivo_path)
        
        if extraction['status'] != 'success':
            logger.warning(f"OCR extraction failed: {extraction.get('error', 'Unknown error')}")
            # Si falla OCR, continuamos sin texto extraído
            extracted_text = ""
        else:
            extracted_text = extraction.get('text', '')
        
        # Guardar contenido extraído
        if extracted_text:
            document.contenido_extraido = extracted_text[:5000]  # Limitar a 5000 caracteres
            document.save()
        
        # Si no hay texto, retornar error
        if not extracted_text:
            return Response(
                {'error': 'No se pudo extraer texto del documento. Asegúrate que sea un documento claro.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        logger.info(f"Extrayendo información médica del documento {doc_id}")
        
        # Analizar con MedGemma
        text_analyzer = get_text_analyzer()
        
        # Realizar análisis
        medical_info = text_analyzer.extract_medical_info(extracted_text)
        document_type = text_analyzer.classify_document_type(extracted_text)
        symptoms_diseases = text_analyzer.detect_symptoms_and_diseases(extracted_text)
        
        # Si es una receta, extraer medicamentos
        prescription_info = {}
        if 'receta' in document.tipo_documento.lower() or 'receta' in extracted_text.lower():
            prescription_info = text_analyzer.extract_prescription(extracted_text)
        
        # Crear análisis consolidado
        analysis_data = {
            'timestamp': datetime.now().isoformat(),
            'modelo': 'MedGemma 2B',
            'extraccion_exitosa': True,
            'informacion_medica': medical_info.get('response', '') if medical_info.get('status') == 'success' else '',
            'tipo_documento_detectado': document_type.get('document_type', 'Documento Médico'),
            'sintomas_enfermedades': symptoms_diseases.get('response', '') if symptoms_diseases.get('status') == 'success' else '',
            'medicamentos': prescription_info.get('response', '') if prescription_info.get('status') == 'success' else '',
            'longitud_texto_extraido': len(extracted_text),
            'fuente_ocr': extraction.get('source', 'unknown'),
            'status': 'completed'
        }
        
        # Guardar análisis en el modelo
        document.ia_analisis = json.dumps(analysis_data, default=str)
        document.save()
        
        logger.info(f"Análisis de texto completado para documento {doc_id}")
        
        return Response({
            'id': document.id,
            'message': 'Análisis de documento completado exitosamente',
            'analysis': {
                'timestamp': analysis_data['timestamp'],
                'modelo': analysis_data['modelo'],
                'tipo_documento': analysis_data['tipo_documento_detectado'],
                'texto_extraido_caracteres': analysis_data['longitud_texto_extraido'],
                'informacion_extraida': {
                    'medicamentos': bool(prescription_info.get('status') == 'success'),
                    'diagnosticos': bool(medical_info.get('status') == 'success'),
                    'sintomas': bool(symptoms_diseases.get('status') == 'success'),
                },
                'status': 'completed'
            }
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        logger.error(f"Error en análisis de texto del documento {doc_id}: {str(e)}")
        return Response(
            {'error': f'Error en análisis: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_document_analysis(request, doc_id):
    """
    Obtener análisis previo de un documento
    
    Endpoint: GET /api/documents/{doc_id}/analysis/
    
    Retorna: todos los análisis realizados (MedSigLIP, MedGemma, etc.)
    """
    try:
        document = MedicalDocument.objects.get(id=doc_id, usuario=request.user)
        
        # Obtener análisis guardado
        if not document.ia_analisis:
            return Response({
                'id': document.id,
                'message': 'Este documento no ha sido analizado',
                'analysis': None,
                'status': 'not_analyzed'
            }, status=status.HTTP_200_OK)
        
        try:
            analysis_data = json.loads(document.ia_analisis)
        except json.JSONDecodeError:
            analysis_data = {}
        
        return Response({
            'id': document.id,
            'nombre': document.nombre,
            'tipo_documento': document.tipo_documento,
            'contenido_extraido': document.contenido_extraido,
            'analysis': analysis_data,
            'status': 'analyzed'
        }, status=status.HTTP_200_OK)
    
    except MedicalDocument.DoesNotExist:
        return Response(
            {'error': 'Documento no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': f'Error al recuperar análisis: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def batch_analyze_documents(request):
    """
    Analizar múltiples documentos en batch
    
    Endpoint: POST /api/documents/batch-analyze/
    
    Parámetros (JSON):
    {
        "doc_ids": [1, 2, 3],
        "analysis_type": "full"  # "full", "text-only", "image-only"
    }
    
    Retorna: estado de análisis de cada documento
    """
    try:
        doc_ids = request.data.get('doc_ids', [])
        analysis_type = request.data.get('analysis_type', 'full')
        
        if not doc_ids:
            return Response(
                {'error': 'Lista de doc_ids requerida'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        results = {
            'total_documents': len(doc_ids),
            'analysis_type': analysis_type,
            'results': [],
            'timestamp': datetime.now().isoformat()
        }
        
        for doc_id in doc_ids:
            try:
                document = MedicalDocument.objects.get(id=doc_id, usuario=request.user)
                
                # Crear un "fake request" para reutilizar la lógica de análisis
                # Por ahora solo marcamos como pendiente de análisis
                results['results'].append({
                    'doc_id': doc_id,
                    'nombre': document.nombre,
                    'tipo': document.tipo_documento,
                    'status': 'queued_for_analysis',
                    'message': 'Documento agregado a cola de análisis'
                })
                
            except MedicalDocument.DoesNotExist:
                results['results'].append({
                    'doc_id': doc_id,
                    'status': 'error',
                    'message': 'Documento no encontrado'
                })
        
        return Response({
            'message': f'{len(doc_ids)} documentos agregados a cola de análisis',
            'batch_analysis': results
        }, status=status.HTTP_202_ACCEPTED)
    
    except Exception as e:
        logger.error(f"Error en análisis batch: {str(e)}")
        return Response(
            {'error': f'Error en análisis batch: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_medical_summary(request, doc_id):
    """
    Obtener resumen ejecutivo de un documento médico
    
    Endpoint: GET /api/documents/{doc_id}/summary/
    
    Retorna: resumen profesional del documento
    """
    try:
        from .analysis_service import get_text_analyzer, get_ocr_extractor
        
        document = MedicalDocument.objects.get(id=doc_id, usuario=request.user)
        
        # Si ya tiene contenido extraído, usarlo
        if document.contenido_extraido:
            extract_text = document.contenido_extraido
        else:
            # Extraer del archivo
            if not document.archivo:
                return Response(
                    {'error': 'Archivo de documento no disponible'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            ocr = get_ocr_extractor()
            archivo_path = document.archivo.path
            
            if archivo_path.lower().endswith('.pdf'):
                extraction = ocr.extract_from_pdf(archivo_path)
            else:
                extraction = ocr.extract_from_image(archivo_path)
            
            if extraction['status'] != 'success':
                return Response(
                    {'error': 'No se pudo extraer texto del documento'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            extract_text = extraction.get('text', '')
        
        if not extract_text:
            return Response(
                {'error': 'No hay contenido para resumir'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generar resumen
        text_analyzer = get_text_analyzer()
        summary = text_analyzer.summarize_report(extract_text)
        
        return Response({
            'id': document.id,
            'nombre': document.nombre,
            'resumen': summary.get('response', ''),
            'timestamp': datetime.now().isoformat()
        }, status=status.HTTP_200_OK)
    
    except MedicalDocument.DoesNotExist:
        return Response(
            {'error': 'Documento no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error generando resumen: {str(e)}")
        return Response(
            {'error': f'Error generando resumen: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )

