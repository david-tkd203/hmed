-- Crear base de datos para SonarQube
CREATE DATABASE sonarqube;

-- Nota: El usuario será creado por PostgreSQL usando POSTGRES_USER
-- Otorgar permisos necesarios al usuario de base de datos
-- Esta configuración presume que POSTGRES_USER es el usuario que ejecuta SonarQube
GRANT ALL PRIVILEGES ON DATABASE hmed_db TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA public TO postgres;

