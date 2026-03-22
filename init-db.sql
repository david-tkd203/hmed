-- ============================================
-- INICIALIZACIÓN PARA PROYECTO HMED
-- ============================================

-- 1. Crear la base de datos para SonarQube
-- La base de datos 'hmed_db' ya fue creada por las variables de entorno de Docker
CREATE DATABASE sonarqube;

-- 2. Asignar al usuario 'admin' como dueño de ambas bases de datos
-- Esto otorga permisos totales de forma automática y recursiva
ALTER DATABASE hmed_db OWNER TO admin;
ALTER DATABASE sonarqube OWNER TO admin;

-- 3. Asegurar privilegios adicionales (Opcional pero recomendado)
GRANT ALL PRIVILEGES ON DATABASE hmed_db TO admin;
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO admin;

-- ============================================
-- NOTA TÉCNICA:
-- No es necesario usar \c (connect) ni GRANT en esquemas aquí.
-- Al ser OWNER, el usuario admin tendrá control total cuando
-- Django y SonarQube inicien sus propias migraciones.
-- ============================================