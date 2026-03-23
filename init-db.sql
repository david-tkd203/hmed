-- ============================================
-- INICIALIZACIÓN BASES DE DATOS - HISTORICO CLINICO  
-- ============================================
-- Este script se ejecuta una sola vez durante la inicialización de PostgreSQL

-- 1. Crear base de datos para SonarQube (IDEMPOTENTE)
-- (hmed_db ya se crea automáticamente via POSTGRES_DB env var)
DO $$ 
BEGIN
  IF NOT EXISTS(SELECT 1 FROM pg_database WHERE datname = 'sonarqube') THEN
    CREATE DATABASE sonarqube;
    RAISE NOTICE 'Base de datos sonarqube creada exitosamente';
  ELSE
    RAISE NOTICE 'Base de datos sonarqube ya existe';
  END IF;
END $$;

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
