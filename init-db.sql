-- ============================================
-- INICIALIZACIÓN BASES DE DATOS - HISTORICO CLINICO  
-- ============================================
-- Bloque idempotente para inicialización de BD

CREATE DATABASE sonarqube;
ALTER DATABASE sonarqube OWNER TO admin;
ALTER DATABASE hmed_db OWNER TO admin;

-- ============================================
-- FIN DE INICIALIZACIÓN
-- ============================================
-- Django: conectará a 'hmed_db' con usuario 'admin'
-- SonarQube: conectará a 'sonarqube' con usuario 'admin'
-- Ambos tienen control total sobre sus respectivas BD's
