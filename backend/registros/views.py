from rest_framework import viewsets, status, serializers
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from .models import Medicamento, Paciente, RegistroClinico
from .serializers import LoginSerializer, RegisterSerializer, UserSerializer, PacienteDetailSerializer
from django_ratelimit.decorators import ratelimit
from django.core.files.uploadedfile import UploadedFile
import mimetypes

# ==================== RATE LIMITING CONFIGURACIÓN ====================
# Login: 5 intentos por hora
# Register: 3 registros por hora  
# File Upload: 20 subidas por hora

class MedicamentoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medicamento
        fields = '__all__'


class MedicamentoViewSet(viewsets.ModelViewSet):
    queryset = Medicamento.objects.all()
    serializer_class = MedicamentoSerializer


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
@ratelimit(key='user_id', rate='30/h', method='PATCH')
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


# ==================== VALIDACIÓN DE ARCHIVOS ====================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@ratelimit(key='user_id', rate='20/h', method='POST')
def validate_file_view(request):
    """
    Endpoint para validar un archivo antes de subirlo
    
    Rate Limit: 20 validaciones por hora por usuario
    
    Recibe: archivo en multipart/form-data
    Retorna: información sobre la validación
    """
    # Manejar rate limit
    if getattr(request, 'limited', False):
        return Response(
            {
                'error': 'Demasiadas validaciones',
                'detail': 'Has excedido el límite de 20 validaciones por hora',
                'retry_after': 'Por favor, intenta en unos minutos'
            },
            status=status.HTTP_429_TOO_MANY_REQUESTS,
            headers={'Retry-After': '600'}
        )
    
    if 'file' not in request.FILES:
        return Response(
            {'error': 'No se proporcionó archivo'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    uploaded_file = request.FILES['file']
    
    # Validar
    validation = validate_file_upload(uploaded_file, max_size_mb=10)
    
    if not validation['valid']:
        return Response(
            {'error': validation['error']},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    return Response({
        'valid': True,
        'file_name': uploaded_file.name,
        'file_size': f"{uploaded_file.size / 1024:.1f} KB",
        'message': 'Archivo válido y listo para subir'
    }, status=status.HTTP_200_OK)


# ==================== REGISTROS CLÍNICOS ====================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@ratelimit(key='user_id', rate='20/h', method='POST')
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


@api_view(['POST'])
@permission_classes([AllowAny])
@ratelimit(key='ip', rate='3/h', method='POST')
def register_view(request):
    """
    Endpoint de Registro con JWT
    Recibe: username, password, email, first_name, last_name, numero_cedula, genero, fecha_nacimiento
    Retorna: access token, refresh token, user info
    """
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
def refresh_token_view(request):
    """
    Endpoint para refrescar access token
    Recibe: refresh token
    Retorna: nuevo access token
    """
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
def update_paciente_profile(request):
    """
    Endpoint para actualizar el perfil del paciente (Onboarding)
    Recibe: campos opcionales - telefono, direccion, ciudad, pais, alergias, enfermedades_cronicas
    Retorna: datos del paciente actualizado
    """
    try:
        paciente = Paciente.objects.get(usuario=request.user)
        
        # Actualizar campos si se proporcionan
        if 'telefono' in request.data:
            paciente.telefono = request.data.get('telefono')
        if 'direccion' in request.data:
            paciente.direccion = request.data.get('direccion')
        if 'ciudad' in request.data:
            paciente.ciudad = request.data.get('ciudad')
        if 'pais' in request.data:
            paciente.pais = request.data.get('pais')
        if 'alergias' in request.data:
            paciente.alergias = request.data.get('alergias')
        if 'enfermedades_cronicas' in request.data:
            paciente.enfermedades_cronicas = request.data.get('enfermedades_cronicas')
        
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
