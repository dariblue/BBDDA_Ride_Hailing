-- =========================================================================
-- SCRIPT DE CONSULTAS Y OPERATIVA - RIDE HAILING APP (Fase 3)
-- DBMS: MySQL / MariaDB
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. CRUD BÁSICO: INSERCIONES DE EJEMPLO
-- -------------------------------------------------------------------------

-- 1.1 Registrar un nuevo Rider (Usuario y Perfil)
INSERT INTO USER (email, password_hash, first_name, last_name, phone, role) 
VALUES ('nuevo_rider@ejemplo.com', 'hash_123', 'Ana', 'Gómez', '+34600123456', 'rider');

-- Obtenemos el último ID para usarlo en la siguiente inserción
SET @nuevo_rider_user_id = LAST_INSERT_ID();

INSERT INTO RIDER_PROFILE (user_id, rating) 
VALUES (@nuevo_rider_user_id, 5.00);


-- 1.2 Registrar un nuevo Driver (Usuario y Perfil)
INSERT INTO USER (email, password_hash, first_name, last_name, phone, role) 
VALUES ('nuevo_driver@ejemplo.com', 'hash_456', 'Carlos', 'Ruiz', '+34611123456', 'driver');

SET @nuevo_driver_user_id = LAST_INSERT_ID();

-- Asumiendo que la compañía 1 ya existe en la base de datos
INSERT INTO DRIVER_PROFILE (user_id, company_id, license_number, rating, status, current_lat, current_lng) 
VALUES (@nuevo_driver_user_id, 1, 'LIC-12345X', 5.00, 'available', 40.4168, -3.7038);

SET @nuevo_driver_id = LAST_INSERT_ID();


-- 1.3 Registrar un nuevo Vehículo para el conductor anterior
INSERT INTO VEHICLE (driver_id, plate, brand, model, year, color, category) 
VALUES (@nuevo_driver_id, '9999 XYZ', 'Tesla', 'Model 3', 2023, 'Blanco', 'premium');


-- 1.4 Solicitar un nuevo Viaje (TRIP)
-- En este punto inicial, driver_id y vehicle_id son NULL
INSERT INTO TRIP (rider_id, origin_lat, origin_lng, origin_address, dest_lat, dest_lng, dest_address, status, price_estimated) 
VALUES (1, 40.4530, -3.6883, 'Estadio Bernabéu, Madrid', 40.4168, -3.7038, 'Puerta del Sol, Madrid', 'requested', 15.50);

SET @nuevo_trip_id = LAST_INSERT_ID();


-- 1.5 Enviar una Oferta (OFFER) a un conductor específico
INSERT INTO OFFER (trip_id, driver_id, status) 
VALUES (@nuevo_trip_id, @nuevo_driver_id, 'pending');


-- -------------------------------------------------------------------------
-- 2. JOINS: HISTORIAL DE VIAJES COMPLETO
-- -------------------------------------------------------------------------

-- 2.1 Historial detallado de viajes con toda la información cruzada
SELECT 
    t.trip_id,
    t.status AS trip_status,
    t.origin_address,
    t.dest_address,
    CONCAT(ur.first_name, ' ', ur.last_name) AS rider_name,
    CONCAT(ud.first_name, ' ', ud.last_name) AS driver_name,
    c.name AS company_name,
    v.brand,
    v.model,
    v.plate,
    t.price_final
FROM TRIP t
JOIN RIDER_PROFILE rp ON t.rider_id = rp.rider_id
JOIN USER ur ON rp.user_id = ur.user_id
LEFT JOIN DRIVER_PROFILE dp ON t.driver_id = dp.driver_id
LEFT JOIN USER ud ON dp.user_id = ud.user_id
LEFT JOIN COMPANY c ON dp.company_id = c.company_id
LEFT JOIN VEHICLE v ON t.vehicle_id = v.vehicle_id
WHERE t.trip_id = 1; -- Filtro de ejemplo por un ID concreto


-- -------------------------------------------------------------------------
-- 3. TRANSACCIÓN CRÍTICA: LOCKS Y CONCURRENCIA PARA ACEPTAR OFERTA
-- -------------------------------------------------------------------------

-- Simulamos variables de sesión para el entorno de prueba
SET @target_offer_id = 1; -- La oferta específica que se va a aceptar
SET @target_driver_id = 1; -- El conductor que pulsa el botón 'Aceptar'

START TRANSACTION;

-- 3.1 Bloqueo Pesimista (Lock) de la oferta
-- El FOR UPDATE evita Race Conditions: si 2 conductores intentan aceptar ofertas
-- del mismo viaje a la vez, o si alguien intenta modificar esta oferta, tendrán que esperar.
SELECT trip_id INTO @target_trip_id FROM OFFER 
WHERE offer_id = @target_offer_id 
  AND driver_id = @target_driver_id
  AND status = 'pending'
FOR UPDATE;

-- 3.2 Cambiar la oferta a 'accepted'
UPDATE OFFER 
SET status = 'accepted', responded_at = CURRENT_TIMESTAMP
WHERE offer_id = @target_offer_id;

-- 3.3 Cambiar TODAS las demás ofertas de este mismo viaje a 'rejected'
UPDATE OFFER 
SET status = 'rejected', responded_at = CURRENT_TIMESTAMP
WHERE trip_id = @target_trip_id 
  AND offer_id != @target_offer_id 
  AND status = 'pending';

-- 3.4 Obtener el vehículo principal del conductor para asignarlo al viaje
SELECT vehicle_id INTO @active_vehicle_id 
FROM VEHICLE 
WHERE driver_id = @target_driver_id LIMIT 1;

-- 3.5 Actualizar el Viaje (TRIP)
UPDATE TRIP 
SET driver_id = @target_driver_id,
    vehicle_id = @active_vehicle_id,
    status = 'accepted',
    accepted_at = CURRENT_TIMESTAMP
WHERE trip_id = @target_trip_id;

-- 3.6 Generar registro preliminar en PAYMENT
-- Se crea en estado 'pending' basado en el price_estimated
INSERT INTO PAYMENT (trip_id, amount, platform_fee, driver_earnings, method, status)
SELECT 
    trip_id, 
    price_estimated, 
    price_estimated * 0.20, 
    price_estimated * 0.80, 
    'card', 
    'pending'
FROM TRIP 
WHERE trip_id = @target_trip_id;

COMMIT;
-- Fin de la transacción


-- -------------------------------------------------------------------------
-- 4. SUBCONSULTAS
-- -------------------------------------------------------------------------

-- 4.1 Top 5 de conductores con mejor rating (Solo conductores en activo)
SELECT 
    dp.driver_id, 
    u.first_name, 
    u.last_name, 
    dp.rating
FROM DRIVER_PROFILE dp
JOIN USER u ON dp.user_id = u.user_id
WHERE dp.driver_id IN (
    SELECT driver_id FROM DRIVER_PROFILE WHERE status != 'offline'
)
ORDER BY dp.rating DESC
LIMIT 5;

-- 4.2 Obtener los viajes en una zona geográfica específica (Subconsulta IN)
SELECT 
    trip_id, origin_address, origin_lat, origin_lng
FROM TRIP
WHERE origin_lat IN (
    SELECT origin_lat FROM TRIP 
    WHERE origin_lat BETWEEN 40.40 AND 40.45
)
AND origin_lng BETWEEN -3.75 AND -3.65;


-- -------------------------------------------------------------------------
-- 5. AGREGACIONES
-- -------------------------------------------------------------------------

-- 5.1 Promedios de tiempo y distancia agrupados por compañía
SELECT 
    c.name AS company_name,
    COUNT(t.trip_id) AS total_trips,
    ROUND(AVG(t.distance_km), 2) AS avg_distance_km,
    ROUND(AVG(t.duration_minutes), 2) AS avg_duration_mins
FROM TRIP t
JOIN DRIVER_PROFILE dp ON t.driver_id = dp.driver_id
JOIN COMPANY c ON dp.company_id = c.company_id
WHERE t.status = 'completed'
GROUP BY c.company_id
ORDER BY total_trips DESC;

-- 5.2 Suma de ganancias por conductor en el último mes
SELECT 
    dp.driver_id,
    CONCAT(u.first_name, ' ', u.last_name) AS driver_name,
    SUM(p.driver_earnings) AS total_earnings_last_month
FROM PAYMENT p
JOIN TRIP t ON p.trip_id = t.trip_id
JOIN DRIVER_PROFILE dp ON t.driver_id = dp.driver_id
JOIN USER u ON dp.user_id = u.user_id
WHERE p.status = 'completed' 
  AND t.finished_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
GROUP BY dp.driver_id, driver_name
ORDER BY total_earnings_last_month DESC;
