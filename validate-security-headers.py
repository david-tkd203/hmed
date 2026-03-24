#!/usr/bin/env python
"""
Security Headers Validator
Valida que todas las cabeceras de seguridad estén presentes y configuradas correctamente
en las respuestas de la API.

Uso:
    python validate-security-headers.py --url http://localhost:8000/api/docs/
"""

import argparse
import requests
import sys
from typing import Dict, List, Tuple
from urllib.parse import urljoin


class SecurityHeaderValidator:
    """Valida cabeceras de seguridad en respuestas HTTP"""
    
    REQUIRED_HEADERS = {
        'Content-Security-Policy': 'default-src',
        'Permissions-Policy': 'camera=()',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
        'Cross-Origin-Resource-Policy': 'same-origin',
        'X-Content-Type-Options': 'nosniff',
        'X-XSS-Protection': '1; mode=block',
        'X-Frame-Options': 'DENY',
    }
    
    FORBIDDEN_HEADERS = {
        'Server': ['gunicorn', 'django', 'python', ' '],  # Evitar versión
        'X-Powered-By': ['*'],  # No debe existir
        'X-AspNet-Version': ['*'],  # No debe existir
    }
    
    def __init__(self, url: str, verbose: bool = False):
        """
        Inicializa el validador
        
        Args:
            url: URL base a validar
            verbose: Mostrar información detallada
        """
        self.url = url
        self.verbose = verbose
        self.headers = {}
        self.status_code = 0
        
    def fetch_headers(self) -> bool:
        """
        Obtiene las cabeceras de la URL
        
        Returns:
            True si es exitoso, False si falla
        """
        try:
            response = requests.head(self.url, timeout=10, allow_redirects=True)
            self.headers = dict(response.headers)
            self.status_code = response.status_code
            
            if self.verbose:
                print(f"[*] Respuesta: {self.status_code}")
            
            return True
        except Exception as e:
            print(f"[✗] Error conectando a {self.url}: {e}")
            return False
    
    def validate_required_headers(self) -> List[Tuple[str, bool, str]]:
        """
        Valida que las cabeceras requeridas estén presentes
        
        Returns:
            Lista de tuplas (header, presente, valor)
        """
        results = []
        
        for header, expected_content in self.REQUIRED_HEADERS.items():
            # Headers en HTTP son case-insensitive, buscar en ambas formas
            value = None
            for key in self.headers:
                if key.lower() == header.lower():
                    value = self.headers[key]
                    break
            
            if value:
                # Verificar que contiene el contenido esperado
                if expected_content.lower() in value.lower():
                    results.append((header, True, value[:80]))
                else:
                    results.append((header, False, f"Presente pero sin '{expected_content}': {value[:60]}"))
            else:
                results.append((header, False, "FALTANTE"))
        
        return results
    
    def validate_forbidden_headers(self) -> List[Tuple[str, bool, str]]:
        """
        Valida que las cabeceras prohibidas no estén presentes o no revelen información
        
        Returns:
            Lista de tuplas (header, válido, detalles)
        """
        results = []
        
        for header, forbidden_values in self.FORBIDDEN_HEADERS.items():
            value = None
            for key in self.headers:
                if key.lower() == header.lower():
                    value = self.headers[key]
                    break
            
            if value is None:
                # Header no presente (es bueno)
                results.append((header, True, "No presente (✓ Correcto)"))
            else:
                # Header presente, verificar contenido
                is_safe = False
                
                if forbidden_values == ['*']:
                    # No debe existir bajo ninguna circunstancia
                    results.append((header, False, f"Presente: {value}"))
                else:
                    # Verificar que no contenga valores reveladores
                    is_safe = not any(
                        forbidden in value.lower() 
                        for forbidden in [v.lower() for v in forbidden_values]
                    )
                    
                    if is_safe:
                        results.append((header, True, f"Genérico: {value}"))
                    else:
                        results.append((header, False, f"Revela versión: {value}"))
        
        return results
    
    def print_report(self):
        """Imprime el reporte de validación"""
        print("\n" + "="*70)
        print(f"VALIDACIÓN DE CABECERAS DE SEGURIDAD")
        print("="*70)
        print(f"URL: {self.url}")
        print(f"Status: {self.status_code}")
        print("="*70)
        
        # Validar cabeceras requeridas
        print("\n[CABECERAS REQUERIDAS]")
        required_results = self.validate_required_headers()
        required_pass = 0
        
        for header, present, value in required_results:
            if present:
                print(f"✅ {header:35} {value}")
                required_pass += 1
            else:
                print(f"❌ {header:35} {value}")
        
        # Validar cabeceras prohibidas
        print("\n[CABECERAS PROHIBIDAS / SENSIBLES]")
        forbidden_results = self.validate_forbidden_headers()
        forbidden_pass = 0
        
        for header, valid, details in forbidden_results:
            if valid:
                print(f"✅ {header:35} {details}")
                forbidden_pass += 1
            else:
                print(f"⚠️  {header:35} {details}")
        
        # Resumen
        total_required = len(required_results)
        total_forbidden = len(forbidden_results)
        total_pass = required_pass + forbidden_pass
        total_checks = total_required + total_forbidden
        
        print("\n" + "="*70)
        print(f"RESULTADO: {total_pass}/{total_checks} validaciones pasadas")
        print("="*70)
        
        # Mostrar puntuación
        percentage = (total_pass / total_checks) * 100
        
        if percentage >= 90:
            print(f"🟢 EXCELENTE: {percentage:.1f}% de conformidad OWASP")
            return 0
        elif percentage >= 70:
            print(f"🟡 BUENO: {percentage:.1f}% de conformidad OWASP")
            return 1
        else:
            print(f"🔴 INSUFICIENTE: {percentage:.1f}% de conformidad OWASP")
            return 2
    
    def validate(self) -> int:
        """
        Ejecuta validación completa
        
        Returns:
            Código de salida (0=éxito, 1=advertencia, 2=error)
        """
        if not self.fetch_headers():
            return 2
        
        return self.print_report()


def main():
    parser = argparse.ArgumentParser(
        description='Validar cabeceras de seguridad HTTP',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  python validate-security-headers.py --url http://localhost:8000/api/docs/
  python validate-security-headers.py --url http://localhost:8000/api/health/ -v
  python validate-security-headers.py --url https://api.prod.local/api/docs/
        """
    )
    
    parser.add_argument(
        '--url',
        required=True,
        help='URL a validar (ej: http://localhost:8000/api/docs/)'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Modo verbose (información detallada)'
    )
    
    args = parser.parse_args()
    
    validator = SecurityHeaderValidator(args.url, args.verbose)
    exit_code = validator.validate()
    
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
