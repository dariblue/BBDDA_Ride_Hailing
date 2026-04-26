#!/bin/bash
# =========================================================================
# SCRIPT DE ESTRATEGIA DE BACKUP - RIDE HAILING APP (Fase 5)
# =========================================================================

# Variables de configuración
DB_NAME="ridehailing"
DB_USER="backup_user"
DB_PASS="B@ckup_Dumps_2026" # En un entorno real, usar ~/.my.cnf o variables de entorno seguras
BACKUP_DIR="/var/backups/ridehailing"
DATE=$(date +"%Y%m%d_%H%M%S")

mkdir -p $BACKUP_DIR

# -------------------------------------------------------------------------
# 1. FULL DUMP DIARIO (Recomendado ejecutar vía Cron a las 3:00 AM)
# -------------------------------------------------------------------------
# Se utiliza --single-transaction para asegurar la consistencia en tablas InnoDB 
# sin bloquear la base de datos entera (sin usar LOCK TABLES masivo).
echo "Iniciando Full Dump Diario..."
mysqldump -u $DB_USER -p$DB_PASS --single-transaction --routines --triggers --events $DB_NAME > $BACKUP_DIR/full_dump_$DATE.sql

# Comprimir para ahorrar espacio
gzip $BACKUP_DIR/full_dump_$DATE.sql
echo "Backup completo guardado en: $BACKUP_DIR/full_dump_$DATE.sql.gz"


# -------------------------------------------------------------------------
# 2. BACKUP INCREMENTAL (Binlogs)
# -------------------------------------------------------------------------
# Extrae los binlogs generados desde la última copia de seguridad. 
# Esto permite restaurar la base de datos hasta el segundo exacto antes de un desastre (Point-in-Time Recovery).
echo "Iniciando Backup Incremental de Binlogs..."

# Primero flusheamos los logs para rotar al siguiente archivo
mysqladmin -u $DB_USER -p$DB_PASS flush-logs

# Copiar los archivos binlog (esto asume la ruta por defecto de MySQL/MariaDB en Linux)
# En un servidor real, esto copiaría los binlogs a un servidor remoto seguro
mkdir -p $BACKUP_DIR/binlogs
cp /var/lib/mysql/mysql-bin.[0-9]* $BACKUP_DIR/binlogs/ 2>/dev/null || echo "No se encontraron binlogs locales o no hay permisos."


# -------------------------------------------------------------------------
# 3. EXPORTACIÓN CSV SEMANAL (Consultas y Outfile)
# -------------------------------------------------------------------------
# Esta consulta se ejecutaría directamente en el motor MySQL para exportar la tabla TRIP a formato CSV.
# Ideal para que el equipo de Data Science analice los viajes de forma offline.

echo "Ejecutando exportación CSV semanal de la tabla TRIP..."

mysql -u $DB_USER -p$DB_PASS -e "
    SELECT 'trip_id', 'rider_id', 'driver_id', 'status', 'distance_km', 'duration_minutes', 'price_final', 'requested_at', 'finished_at'
    UNION ALL
    SELECT trip_id, rider_id, IFNULL(driver_id, 'N/A'), status, distance_km, duration_minutes, price_final, requested_at, IFNULL(finished_at, 'N/A')
    INTO OUTFILE '/var/lib/mysql-files/trip_export_$DATE.csv'
    FIELDS TERMINATED BY ',' 
    ENCLOSED BY '\"'
    LINES TERMINATED BY '\n'
    FROM ridehailing.TRIP;
"
echo "Exportación CSV completada en: /var/lib/mysql-files/trip_export_$DATE.csv"
