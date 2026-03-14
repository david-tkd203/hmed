from rest_framework import serializers
from django.contrib.auth.models import User
from registros.models import Paciente


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']


class PacienteDetailSerializer(serializers.ModelSerializer):
    usuario = UserSerializer(read_only=True)
    
    class Meta:
        model = Paciente
        fields = [
            'id', 'usuario', 'numero_cedula', 'genero', 'fecha_nacimiento',
            'telefono', 'direccion', 'ciudad', 'pais', 'alergias',
            'enfermedades_cronicas', 'foto_perfil', 'creado_en', 'actualizado_en'
        ]
        read_only_fields = ['id', 'creado_en', 'actualizado_en']


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(max_length=128, write_only=True)


class RegisterSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(max_length=128, write_only=True, min_length=6)
    email = serializers.EmailField()
    first_name = serializers.CharField(max_length=150, required=False)
    last_name = serializers.CharField(max_length=150, required=False)
    numero_cedula = serializers.CharField(max_length=20)
    genero = serializers.ChoiceField(choices=['M', 'F', 'O'], default='M')
    fecha_nacimiento = serializers.DateField()

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("El username ya está registrado")
        return value

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("El email ya está registrado")
        return value

    def validate_numero_cedula(self, value):
        if Paciente.objects.filter(numero_cedula=value).exists():
            raise serializers.ValidationError("La cédula ya está registrada")
        return value
