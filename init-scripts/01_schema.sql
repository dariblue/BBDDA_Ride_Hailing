-- =========================================================================
-- SCRIPT DE CREACIÓN DE ESQUEMA - RIDE HAILING APP
-- DBMS: MySQL / MariaDB
-- =========================================================================

-- 1. ELIMINACIÓN DE TABLAS EN ORDEN INVERSO (para no violar FKs)
DROP TABLE IF EXISTS AUDIT_LOG;
DROP TABLE IF EXISTS PAYMENT;
DROP TABLE IF EXISTS OFFER;
DROP TABLE IF EXISTS TRIP;
DROP TABLE IF EXISTS VEHICLE;
DROP TABLE IF EXISTS DRIVER_PROFILE;
DROP TABLE IF EXISTS RIDER_PROFILE;
DROP TABLE IF EXISTS COMPANY;
DROP TABLE IF EXISTS USER;

-- 2. CREACIÓN DE TABLAS (respetando dependencias)

CREATE TABLE USER (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    role ENUM('rider', 'driver') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE COMPANY (
    company_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    tax_id VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE RIDER_PROFILE (
    rider_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    rating DECIMAL(10,2) DEFAULT 5.00,
    CONSTRAINT fk_rider_user FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE
);

CREATE TABLE DRIVER_PROFILE (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    company_id INT,
    license_number VARCHAR(100) NOT NULL UNIQUE,
    rating DECIMAL(10,2) DEFAULT 5.00,
    status ENUM('available', 'busy', 'offline') DEFAULT 'offline',
    current_lat DECIMAL(10,8),
    current_lng DECIMAL(10,8),
    CONSTRAINT fk_driver_user FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_driver_company FOREIGN KEY (company_id) REFERENCES COMPANY(company_id) ON DELETE SET NULL
);

CREATE TABLE VEHICLE (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    plate VARCHAR(20) NOT NULL UNIQUE,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    color VARCHAR(30),
    category ENUM('economy', 'comfort', 'premium') DEFAULT 'economy',
    CONSTRAINT fk_vehicle_driver FOREIGN KEY (driver_id) REFERENCES DRIVER_PROFILE(driver_id) ON DELETE CASCADE
);

CREATE TABLE TRIP (
    trip_id INT AUTO_INCREMENT PRIMARY KEY,
    rider_id INT NOT NULL,
    driver_id INT NULL,
    vehicle_id INT NULL,
    origin_lat DECIMAL(10,8) NOT NULL,
    origin_lng DECIMAL(10,8) NOT NULL,
    origin_address VARCHAR(255) NOT NULL,
    dest_lat DECIMAL(10,8) NOT NULL,
    dest_lng DECIMAL(10,8) NOT NULL,
    dest_address VARCHAR(255) NOT NULL,
    status ENUM('requested', 'accepted', 'in_progress', 'completed', 'cancelled') DEFAULT 'requested',
    distance_km DECIMAL(10,2),
    duration_minutes INT,
    price_estimated DECIMAL(10,2) NOT NULL,
    price_final DECIMAL(10,2),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    started_at TIMESTAMP NULL,
    finished_at TIMESTAMP NULL,
    CONSTRAINT fk_trip_rider FOREIGN KEY (rider_id) REFERENCES RIDER_PROFILE(rider_id) ON DELETE RESTRICT,
    CONSTRAINT fk_trip_driver FOREIGN KEY (driver_id) REFERENCES DRIVER_PROFILE(driver_id) ON DELETE SET NULL,
    CONSTRAINT fk_trip_vehicle FOREIGN KEY (vehicle_id) REFERENCES VEHICLE(vehicle_id) ON DELETE SET NULL
);

CREATE TABLE OFFER (
    offer_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL,
    driver_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'rejected', 'expired') DEFAULT 'pending',
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP NULL,
    CONSTRAINT fk_offer_trip FOREIGN KEY (trip_id) REFERENCES TRIP(trip_id) ON DELETE CASCADE,
    CONSTRAINT fk_offer_driver FOREIGN KEY (driver_id) REFERENCES DRIVER_PROFILE(driver_id) ON DELETE CASCADE
);

CREATE TABLE PAYMENT (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    platform_fee DECIMAL(10,2) NOT NULL,
    driver_earnings DECIMAL(10,2) NOT NULL,
    method ENUM('card', 'cash', 'wallet') NOT NULL,
    status ENUM('pending', 'completed', 'refunded') DEFAULT 'pending',
    paid_at TIMESTAMP NULL,
    CONSTRAINT fk_payment_trip FOREIGN KEY (trip_id) REFERENCES TRIP(trip_id) ON DELETE RESTRICT
);

CREATE TABLE AUDIT_LOG (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    old_values JSON,
    new_values JSON,
    performed_by VARCHAR(100),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================================
-- 3. CREACIÓN DE ÍNDICES CRÍTICOS
-- =========================================================================

-- Índice para búsquedas rápidas de usuario por email en los inicios de sesión
CREATE INDEX idx_user_email ON USER(email);

-- Índice para filtrar rápidamente a los usuarios por su rol
CREATE INDEX idx_user_role ON USER(role);

-- Índice para búsquedas geo-espaciales o estados (encontrar conductores disponibles rápidamente)
CREATE INDEX idx_driver_status ON DRIVER_PROFILE(status);

-- Índice para monitorizar viajes activos o filtrar el historial de viajes
CREATE INDEX idx_trip_status ON TRIP(status);
