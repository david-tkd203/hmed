-- ============================================
-- INICIALIZACIÓN BASES DE DATOS - HISTORICO CLINICO  
-- ============================================
-- Bloque idempotente para inicialización de BD

-- Crear base de datos SonarQube
CREATE DATABASE sonarqube;
ALTER DATABASE sonarqube OWNER TO admin;

-- Crear base de datos Django
ALTER DATABASE hmed_db OWNER TO admin;

-- Asegurar permisos SUPERUSER para admin (requerido por SonarQube para extensiones internas)
ALTER USER admin WITH SUPERUSER CREATEDB CREATEROLE;

-- Granting explicit permissions on sonarqube database
GRANT CONNECT ON DATABASE sonarqube TO admin;
GRANT USAGE ON SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON SCHEMA public TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO admin;

-- ============================================
-- FIN DE INICIALIZACIÓN
-- ============================================
-- Django: conectará a 'hmed_db' con usuario 'admin'
-- SonarQube: conectará a 'sonarqube' con usuario 'admin' (como SUPERUSER)
-- Ambos tienen control total sobre sus respectivas BD's
