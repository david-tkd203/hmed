-- ============================================
-- INICIALIZACIÓN BASES DE DATOS - HISTORICO CLINICO  
-- ============================================

CREATE DATABASE sonarqube;
ALTER USER admin WITH SUPERUSER;
ALTER DATABASE sonarqube OWNER TO admin;

-- ============================================
-- FIN DE INICIALIZACIÓN
-- ============================================
-- Django: conectará a 'hmed_db' con usuario 'admin'
-- SonarQube: conectará a 'sonarqube' con usuario 'admin' (como SUPERUSER)
-- Ambos tienen control total sobre sus respectivas BD's
