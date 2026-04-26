-- =========================================================================
-- SCRIPT DE DASHBOARDS (GRAFANA) - RIDE HAILING APP (Fase 4)
-- DBMS: MySQL / MariaDB
-- =========================================================================

-- =========================================================================
-- BLOQUE 1: DASHBOARD DE NEGOCIO
-- =========================================================================

-- 1.1 Viajes por día (Serie temporal para gráfico de líneas/barras)
-- Cuenta los viajes solicitados agrupados por la fecha
SELECT 
    DATE(requested_at) AS Fecha,
    COUNT(trip_id) AS Total_Viajes
FROM TRIP
GROUP BY DATE(requested_at)
ORDER BY Fecha ASC;

-- 1.2 Tasa de aceptación por conductor (Ratio de conversión)
-- Porcentaje de ofertas aceptadas frente al total de ofertas recibidas
SELECT 
    o.driver_id AS ID_Conductor,
    CONCAT(u.first_name, ' ', u.last_name) AS Nombre_Conductor,
    COUNT(o.offer_id) AS Total_Ofertas,
    SUM(CASE WHEN o.status = 'accepted' THEN 1 ELSE 0 END) AS Ofertas_Aceptadas,
    ROUND((SUM(CASE WHEN o.status = 'accepted' THEN 1 ELSE 0 END) / COUNT(o.offer_id)) * 100, 2) AS Tasa_Aceptacion_Porcentaje
FROM OFFER o
JOIN DRIVER_PROFILE dp ON o.driver_id = dp.driver_id
JOIN USER u ON dp.user_id = u.user_id
GROUP BY o.driver_id
ORDER BY Tasa_Aceptacion_Porcentaje DESC;

-- 1.3 Tasa de aceptación por compañía
-- Cruzamos con COMPANY para agrupar las métricas de sus conductores
SELECT 
    c.name AS Nombre_Compania,
    COUNT(o.offer_id) AS Total_Ofertas,
    SUM(CASE WHEN o.status = 'accepted' THEN 1 ELSE 0 END) AS Ofertas_Aceptadas,
    ROUND((SUM(CASE WHEN o.status = 'accepted' THEN 1 ELSE 0 END) / COUNT(o.offer_id)) * 100, 2) AS Tasa_Aceptacion_Porcentaje
FROM OFFER o
JOIN DRIVER_PROFILE dp ON o.driver_id = dp.driver_id
JOIN COMPANY c ON dp.company_id = c.company_id
GROUP BY c.company_id
ORDER BY Tasa_Aceptacion_Porcentaje DESC;

-- 1.4 Promedios de servicio (Calidad y eficiencia)
-- Tiempo medio y distancia media de los viajes completados
SELECT 
    ROUND(AVG(duration_minutes), 2) AS Tiempo_Medio_Minutos,
    ROUND(AVG(distance_km), 2) AS Distancia_Media_Km
FROM TRIP
WHERE status = 'completed';

-- 1.5 Rendimiento Económico Global y Rentabilidad
-- Suma total de ganancias e ingresos por km/min
SELECT 
    ROUND(SUM(p.driver_earnings), 2) AS Ganancias_Conductores_Euros,
    ROUND(SUM(p.platform_fee), 2) AS Ingresos_Plataforma_Euros,
    ROUND(SUM(p.amount) / SUM(t.distance_km), 2) AS Rentabilidad_Euros_Por_Km,
    ROUND(SUM(p.amount) / SUM(t.duration_minutes), 2) AS Rentabilidad_Euros_Por_Minuto
FROM PAYMENT p
JOIN TRIP t ON p.trip_id = t.trip_id
WHERE p.status = 'completed';

-- 1.6 Ranking: Top 5 conductores con más ingresos generados
SELECT 
    dp.driver_id AS ID_Conductor,
    CONCAT(u.first_name, ' ', u.last_name) AS Nombre_Conductor,
    ROUND(SUM(p.driver_earnings), 2) AS Total_Ganancias_Euros
FROM PAYMENT p
JOIN TRIP t ON p.trip_id = t.trip_id
JOIN DRIVER_PROFILE dp ON t.driver_id = dp.driver_id
JOIN USER u ON dp.user_id = u.user_id
WHERE p.status = 'completed'
GROUP BY dp.driver_id
ORDER BY Total_Ganancias_Euros DESC
LIMIT 5;

-- 1.7 Ranking: Top 3 de compañías con mayor facturación total (Amount)
SELECT 
    c.name AS Nombre_Compania,
    ROUND(SUM(p.amount), 2) AS Facturacion_Total_Euros
FROM PAYMENT p
JOIN TRIP t ON p.trip_id = t.trip_id
JOIN DRIVER_PROFILE dp ON t.driver_id = dp.driver_id
JOIN COMPANY c ON dp.company_id = c.company_id
WHERE p.status = 'completed'
GROUP BY c.company_id
ORDER BY Facturacion_Total_Euros DESC
LIMIT 3;


-- =========================================================================
-- BLOQUE 2: DASHBOARD DE BASE DE DATOS (DBA)
-- =========================================================================

-- 2.1 Conexiones activas e hilos de ejecución
-- Permite monitorizar en tiempo real si hay consultas bloqueadas o alta carga
SELECT 
    ID AS ID_Proceso,
    USER AS Usuario,
    HOST AS Origen,
    DB AS Base_Datos,
    COMMAND AS Comando,
    TIME AS Tiempo_Segundos,
    STATE AS Estado,
    INFO AS Consulta_SQL
FROM information_schema.PROCESSLIST
WHERE USER != 'system user'
ORDER BY Tiempo_Segundos DESC;

-- 2.2 Tamaño de las tablas en disco (Métricas de almacenamiento)
-- Devuelve el tamaño en MB de cada tabla de la base de datos actual
SELECT 
    TABLE_NAME AS Tabla,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS Tamano_MB,
    TABLE_ROWS AS Filas_Aproximadas
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'ridehailing'
ORDER BY Tamano_MB DESC;

-- 2.3 Estado de métricas clave del servidor (Performance general)
-- Variables vitales de salud de MariaDB/MySQL
SHOW GLOBAL STATUS WHERE Variable_name IN (
    'Questions',                -- Queries ejecutadas totales (Tráfico)
    'Uptime',                   -- Segundos activa
    'Threads_connected',        -- Conexiones simultáneas
    'Slow_queries',             -- Consultas lentas registradas
    'Innodb_buffer_pool_reads'  -- Accesos al disco vs Caché
);
