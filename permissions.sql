-- =========================================================================
-- SCRIPT DE SEGURIDAD Y PERMISOS - RIDE HAILING APP (Fase 5)
-- DBMS: MySQL / MariaDB
-- =========================================================================

-- 1. DBA (Administrador Total)
CREATE USER IF NOT EXISTS 'admin_ridehailing' @'%' IDENTIFIED BY 'AdminStr0ngP@ssw0rd!';

GRANT ALL PRIVILEGES ON *.* TO 'admin_ridehailing' @'%'
WITH
GRANT OPTION;

-- 2. Usuario de Aplicación (Backend)
-- Mínimo privilegio: Solo operaciones DML en tablas operativas. Sin DROP, ALTER ni DELETE masivo.
CREATE USER IF NOT EXISTS 'app_backend' @'%' IDENTIFIED BY 'B@ck3nd_S3cur3_99';

GRANT
SELECT,
INSERT
,
UPDATE ON ridehailing.USER TO 'app_backend' @'%';

GRANT
SELECT,
INSERT
,
UPDATE ON ridehailing.RIDER_PROFILE TO 'app_backend' @'%';

GRANT
SELECT,
INSERT
,
UPDATE ON ridehailing.DRIVER_PROFILE TO 'app_backend' @'%';

GRANT
SELECT,
INSERT
,
UPDATE ON ridehailing.COMPANY TO 'app_backend' @'%';

GRANT
SELECT,
INSERT
,
UPDATE ON ridehailing.VEHICLE TO 'app_backend' @'%';

GRANT
SELECT,
INSERT
,
UPDATE ON ridehailing.TRIP TO 'app_backend' @'%';

GRANT
SELECT,
INSERT
,
UPDATE ON ridehailing.OFFER TO 'app_backend' @'%';

GRANT
SELECT,
INSERT
,
UPDATE ON ridehailing.PAYMENT TO 'app_backend' @'%';

-- 3. Usuario de Lectura para Dashboards (Grafana)
-- Mínimo privilegio: Solo lectura global para evitar inyecciones que modifiquen datos
CREATE USER IF NOT EXISTS 'dashboard_reader' @'%' IDENTIFIED BY 'Gr@fanaR3ad0nly!';

GRANT SELECT ON ridehailing.* TO 'dashboard_reader' @'%';

-- 4. Usuario Auditor
-- Mínimo privilegio: Solo puede consultar la tabla de logs de auditoría
CREATE USER IF NOT EXISTS 'auditor' @'%' IDENTIFIED BY 'Aud1t0r_V13w3r';

GRANT SELECT ON ridehailing.AUDIT_LOG TO 'auditor' @'%';

-- 5. Usuario de Backup
-- Mínimo privilegio: Permisos específicos para hacer mysqldump sin detener la base de datos
CREATE USER IF NOT EXISTS 'backup_user' @'localhost' IDENTIFIED BY 'B@ckup_Dumps_2026';

GRANT
SELECT,
LOCK TABLES,
SHOW VIEW, EVENT, TRIGGER ON ridehailing.* TO 'backup_user' @'localhost';

GRANT RELOAD ON *.* TO 'backup_user' @'localhost';

-- Aplicar los cambios inmediatamente
FLUSH PRIVILEGES;