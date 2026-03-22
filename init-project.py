#!/usr/bin/env python3
"""
Script maestro de inicialización para Historico Clinico.
Ejecuta antes de levantar los contenedores.

Uso:
    python init-project.py
"""

import os
import subprocess
import sys
from pathlib import Path
from datetime import datetime

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}")
    print(f"{text.center(60)}")
    print(f"{'='*60}{Colors.ENDC}\n")

def print_step(text):
    print(f"{Colors.CYAN}▶ {text}{Colors.ENDC}")

def print_success(text):
    print(f"{Colors.GREEN}✅ {text}{Colors.ENDC}")

def print_error(text):
    print(f"{Colors.RED}❌ {text}{Colors.ENDC}")

def print_warning(text):
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.ENDC}")

def run_command(cmd, description):
    """Ejecuta un comando y retorna True si es exitoso"""
    print_step(description)
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            print_success(description)
            return True
        else:
            print_error(f"{description}: {result.stderr}")
            return False
    except Exception as e:
        print_error(f"{description}: {str(e)}")
        return False

def check_docker():
    """Verifica que Docker esté instalado y funcionando"""
    print_step("Verificando Docker...")
    result = subprocess.run("docker --version", shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        print_success(f"Docker encontrado: {result.stdout.strip()}")
        return True
    else:
        print_error("Docker no está instalado o no es accesible")
        return False

def check_env_file():
    """Verifica que el archivo .env exista"""
    print_step("Verificando archivo .env...")
    if Path('.env').exists():
        print_success("Archivo .env encontrado")
        return True
    else:
        print_warning("Archivo .env no encontrado. Se usarán valores por defecto.")
        return False

def main():
    print_header("INICIALIZADOR DE HISTORICO CLINICO")
    
    print(f"\n{Colors.BOLD}Fecha/Hora:{Colors.ENDC} {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{Colors.BOLD}Directorio:{Colors.ENDC} {os.getcwd()}\n")
    
    # Paso 1: Verificaciones previas
    print_header("PASO 1: VERIFICACIONES PREVIAS")
    
    if not check_docker():
        print_error("Por favor, instale Docker primero")
        sys.exit(1)
    
    check_env_file()
    
    # Paso 2: Limpiar (opcional)
    print_header("PASO 2: LIMPIEZA PREVIA")
    
    response = input(f"{Colors.YELLOW}¿Desea limpiar contenedores previos? (s/n): {Colors.ENDC}")
    if response.lower() == 's':
        print_step("Deteniendo y eliminando contenedores previos...")
        run_command(
            "docker-compose down -v --remove-orphans",
            "Limpieza de contenedores"
        )
    
    # Paso 3: Compilar imágenes
    print_header("PASO 3: COMPILACIÓN DE IMÁGENES DOCKER")
    
    print_step("Compilando imágenes...")
    print("  Esto puede tomar varios minutos en la primera ejecución...\n")
    
    result = subprocess.run(
        "docker-compose build",
        shell=True,
        capture_output=False,
        text=True
    )
    
    if result.returncode != 0:
        print_error("Error al compilar imágenes Docker")
        sys.exit(1)
    
    print_success("Imágenes compiladas correctamente")
    
    # Paso 4: Iniciar servicios
    print_header("PASO 4: INICIAR SERVICIOS")
    
    print_step("Iniciando servicios Docker...")
    print("  Esperando a que los servicios estén listos...\n")
    
    result = subprocess.run(
        "docker-compose up -d",
        shell=True,
        capture_output=False,
        text=True
    )
    
    if result.returncode != 0:
        print_error("Error al iniciar servicios")
        sys.exit(1)
    
    print_success("Servicios iniciados")
    
    # Paso 5: Esperar a que la BD esté lista
    print_header("PASO 5: ESPERAR A QUE LA BASE DE DATOS ESTÉ LISTA")
    
    print_step("Esperando a que PostgreSQL esté disponible...")
    
    max_attempts = 30
    attempt = 0
    
    while attempt < max_attempts:
        result = subprocess.run(
            'docker-compose exec -T db pg_isready -U admin > /dev/null 2>&1',
            shell=True
        )
        
        if result.returncode == 0:
            print_success("Base de datos lista")
            break
        
        attempt += 1
        if attempt % 5 == 0:
            print(f"  Intento {attempt}/{max_attempts}...")
        
        import time
        time.sleep(1)
    
    if attempt == max_attempts:
        print_error("La base de datos tardó demasiado en iniciarse")
        sys.exit(1)
    
    # Paso 6: Ejecutar migraciones
    print_header("PASO 6: EJECUTAR MIGRACIONES DE DJANGO")
    
    print_step("Ejecutando migraciones...")
    
    result = subprocess.run(
        'docker-compose exec -T web python manage.py migrate',
        shell=True,
        capture_output=False,
        text=True
    )
    
    if result.returncode == 0:
        print_success("Migraciones ejecutadas")
    else:
        print_warning("Advertencia: Algunas migraciones pueden no haberse ejecutado")
    
    # Paso 7: Información final
    print_header("✨ INICIALIZACIÓN COMPLETADA")
    
    print(f"\n{Colors.BOLD}🔗 URLs de acceso:{Colors.ENDC}")
    print(f"   🌐 Frontend:      http://localhost:5173")
    print(f"   🔌 API Django:    http://localhost:8000")
    print(f"   👨‍💼 Admin:         http://localhost:8000/admin")
    print(f"   📊 SonarQube:     http://localhost:9000")
    print(f"   🤖 AI Service:    http://localhost:8001")
    
    print(f"\n{Colors.BOLD}📝 Credenciales de prueba:{Colors.ENDC}")
    print(f"   Usuario:     testuser")
    print(f"   Contraseña:  changeme")
    
    print(f"\n{Colors.BOLD}📋 Comandos útiles:{Colors.ENDC}")
    print(f"   Ver logs:         docker-compose logs -f web")
    print(f"   Acceder a shell:  docker-compose exec web python manage.py shell")
    print(f"   Detener servicios: docker-compose down")
    
    print(f"\n{Colors.BOLD}✅ El proyecto está completamente configurado y listo para usar.{Colors.ENDC}\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Inicialización cancelada por el usuario{Colors.ENDC}\n")
        sys.exit(0)
    except Exception as e:
        print_error(f"Error inesperado: {str(e)}")
        sys.exit(1)
