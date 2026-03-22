-- ============================================
-- INICIALIZACIÓN DE BASE DE DATOS HISTORICO CLINICO
-- ============================================

-- Crear base de datos para SonarQube (separada de Django)
CREATE DATABASE sonarqube;

-- Crear base de datos para Django (hmed_db ya se crea vía POSTGRES_DB)
-- Pero garantizamos que exista explícitamente
CREATE DATABASE IF NOT EXISTS hmed_db;

-- ============================================
-- ASIGNAR PERMISOS AL USUARIO admin
-- ============================================

-- Permisos para la base de datos de aplicación
GRANT ALL PRIVILEGES ON DATABASE hmed_db TO admin;

-- Permisos para la base de datos de SonarQube
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO admin;

-- Permisos de esquema en la base de datos hmed_db
GRANT ALL PRIVILEGES ON SCHEMA public TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO admin;

-- Permisos de esquema en la base de datos sonarqube
\c sonarqube
GRANT ALL PRIVILEGES ON SCHEMA public TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO admin;

-- Volver a la base de datos por defecto
\c hmed_db

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================
-- El servidor está listo para aceptar conexiones desde:
-- 1. Django en hmed_db con usuario admin
-- 2. SonarQube en sonarqube con usuario admin

