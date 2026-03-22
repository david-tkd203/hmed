-- ============================================
-- INICIALIZACIÓN BASES DE DATOS - HISTORICO CLINICO  
-- ============================================
-- Este script se ejecuta una sola vez durante la inicialización de PostgreSQL

-- 1. Crear base de datos para SonarQube
-- (hmed_db ya se crea automáticamente via POSTGRES_DB env var)
CREATE DATABASE sonarqube;

-- 2. Asignar OWNER a las bases de datos al usuario 'admin'
-- Esto permite que Django y SonarQube tengan control total
ALTER DATABASE hmed_db OWNER TO admin;
ALTER DATABASE sonarqube OWNER TO admin;

-- 3. Dar permisos de SUPERUSER a 'admin'
-- SonarQube requiere algunos permisos elevados
ALTER USER admin WITH SUPERUSER;

-- ============================================
-- FIN DE INICIALIZACIÓN
-- ============================================
-- Django: conectará a 'hmed_db' con usuario 'admin'
-- SonarQube: conectará a 'sonarqube' con usuario 'admin'
-- Ambos tienen control total sobre sus respectivas BD's
