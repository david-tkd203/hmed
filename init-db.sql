-- Crear base de datos para SonarQube
CREATE DATABASE sonarqube;

-- Crear usuario para SonarQube con permisos completos
CREATE USER sonar_user WITH PASSWORD 'sonar_password';
ALTER USER sonar_user CREATEDB;
ALTER DATABASE sonarqube OWNER TO sonar_user;

-- Otorgar permisos necesarios
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO sonar_user;
