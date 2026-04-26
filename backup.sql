-- =========================================================================
-- SCRIPT DE BACKUP LÓGICO Y ARCHIVADO - RIDE HAILING APP (Fase 5)
-- Nota académica: El backup completo de una BD se hace mediante terminal 
-- con 'mysqldump'. Este script muestra estrategias de backup lógico, 
-- exportación de datos y archivado utilizando puramente SQL.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. HABILITAR EL PROGRAMADOR DE EVENTOS (EVENT SCHEDULER)
-- -------------------------------------------------------------------------
-- Necesario para automatizar tareas de backup o limpieza dentro de MySQL
SET GLOBAL event_scheduler = ON;

-- -------------------------------------------------------------------------
-- 2. TABLAS DE ARCHIVO (COLD STORAGE BACKUP)
-- -------------------------------------------------------------------------
-- Creamos tablas idénticas a las operativas para guardar el histórico.
-- Esto es una forma de "backup interno" para no sobrecargar las tablas principales.
CREATE TABLE IF NOT EXISTS TRIP_ARCHIVE LIKE TRIP;
CREATE TABLE IF NOT EXISTS AUDIT_LOG_ARCHIVE LIKE AUDIT_LOG;

-- -------------------------------------------------------------------------
-- 3. EVENTOS DE BACKUP Y ARCHIVADO AUTOMÁTICO
-- -------------------------------------------------------------------------
DELIMITER //

-- Evento: Cada semana, mover los viajes muy antiguos (más de 1 año) al archivo
CREATE EVENT IF NOT EXISTS ev_backup_old_trips
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    -- Copiar datos históricos al archivo
    INSERT INTO TRIP_ARCHIVE
    SELECT * FROM TRIP 
    WHERE status IN ('completed', 'cancelled') 
      AND finished_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);
      
    -- Nota: En un entorno de producción estricto, aquí iría un DELETE de la tabla TRIP
    -- para aligerarla, pero lo dejamos solo como copia (backup) por seguridad.
END //

-- Evento: Backup mensual de los logs de auditoría
CREATE EVENT IF NOT EXISTS ev_backup_audit_logs
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO AUDIT_LOG_ARCHIVE
    SELECT * FROM AUDIT_LOG
    WHERE performed_at < DATE_SUB(NOW(), INTERVAL 6 MONTH);
END //

DELIMITER ;


-- -------------------------------------------------------------------------
-- 4. EXPORTACIÓN MANUAL DE DATOS (BACKUP A ARCHIVOS CSV)
-- -------------------------------------------------------------------------
-- Extrae directamente el contenido de las tablas a archivos físicos de texto.
-- Nota: La carpeta '/var/lib/mysql-files/' es la carpeta segura por defecto de MySQL para outfiles.

-- 4.1 Exportar todos los Usuarios (Backup de PII - Datos Personales)
SELECT * 
INTO OUTFILE '/tmp/backup_users_current.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
FROM USER;

-- 4.2 Exportar todo el historial de Pagos (Backup Financiero)
SELECT * 
INTO OUTFILE '/tmp/backup_payments_current.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
FROM PAYMENT;


-- =========================================================================
-- ANEXO: COMANDOS DE CONSOLA PARA EL DBA (BACKUP TOTAL)
-- =========================================================================
/*
Para justificarlo en la defensa: Los backups completos (Estructura + Datos) 
no se hacen con sentencias SQL internas, sino con la herramienta externa 'mysqldump'.

Comando para Backup Completo (Diario):
> mysqldump -u backup_user -p --single-transaction --routines --triggers ridehailing > backup_full.sql

Comando para Restauración (Disaster Recovery):
> mysql -u admin_ridehailing -p ridehailing < backup_full.sql
*/
