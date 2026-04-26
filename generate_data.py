import random
from datetime import datetime, timedelta
import math
from faker import Faker

fake = Faker('es_ES')

# Configuración
NUM_COMPANIES = 5
NUM_RIDERS = 100
NUM_DRIVERS = 50
NUM_VEHICLES = 50
NUM_TRIPS = 1000

# Vehículos comunes en España
BRANDS_MODELS = {
    'Toyota': ['Corolla', 'Prius', 'Camry', 'Yaris'],
    'Hyundai': ['Ioniq', 'Tucson', 'Kona'],
    'Kia': ['Niro', 'Sportage', 'Ceed'],
    'Tesla': ['Model 3', 'Model Y'],
    'Skoda': ['Octavia', 'Superb']
}

def escape(val):
    """Escapa strings para SQL y maneja NULLs."""
    if val is None:
        return 'NULL'
    if isinstance(val, str):
        val = val.replace("'", "''")
        return f"'{val}'"
    return str(val)

def format_dt(dt):
    if dt is None:
        return 'NULL'
    return f"'{dt.strftime('%Y-%m-%d %H:%M:%S')}'"

def random_lat_lng_madrid():
    lat = round(random.uniform(40.35, 40.50), 8)
    lng = round(random.uniform(-3.75, -3.60), 8)
    return lat, lng

def generate_plate():
    # Formato español: 4 números y 3 consonantes
    nums = f"{random.randint(0, 9999):04d}"
    consonants = "BCDFGHJKLMNPRSTVWXYZ"
    letters = ''.join(random.choices(consonants, k=3))
    return f"{nums} {letters}"

def run():
    print("Generando datos...")
    
    with open('data.sql', 'w', encoding='utf-8') as f:
        f.write("-- =========================================================================\n")
        f.write("-- SCRIPT DE DATOS DE PRUEBA - RIDE HAILING APP\n")
        f.write("-- =========================================================================\n\n")
        
        f.write("SET FOREIGN_KEY_CHECKS = 0;\n\n")

        # 1. COMPANIES
        f.write("-- COMPAÑÍAS\n")
        for i in range(1, NUM_COMPANIES + 1):
            name = fake.company()
            tax_id = fake.vat_id()
            email = f"info@{name.lower().replace(' ', '').replace(',', '')}.com"
            dt = fake.date_time_between(start_date='-2y', end_date='-1y')
            f.write(f"INSERT INTO COMPANY (company_id, name, tax_id, email, created_at) VALUES ({i}, {escape(name)}, {escape(tax_id)}, {escape(email)}, {format_dt(dt)});\n")
        
        f.write("\n")

        # 2. USERS (Riders 1-100, Drivers 101-150)
        f.write("-- USUARIOS (RIDERS Y DRIVERS)\n")
        total_users = NUM_RIDERS + NUM_DRIVERS
        for i in range(1, total_users + 1):
            role = 'rider' if i <= NUM_RIDERS else 'driver'
            first_name = fake.first_name()
            last_name = fake.last_name()
            email = f"{first_name.lower()}.{last_name.lower()}{i}@ejemplo.com"
            pwd = "hash_falso_12345"
            phone = f"+34{random.randint(600000000, 699999999)}"
            is_active = random.choice(['TRUE', 'TRUE', 'TRUE', 'FALSE']) # 75% activos
            dt = fake.date_time_between(start_date='-1y', end_date='-4m')
            
            f.write(f"INSERT INTO USER (user_id, email, password_hash, first_name, last_name, phone, role, is_active, created_at) ")
            f.write(f"VALUES ({i}, {escape(email)}, {escape(pwd)}, {escape(first_name)}, {escape(last_name)}, {escape(phone)}, {escape(role)}, {is_active}, {format_dt(dt)});\n")

        f.write("\n")

        # 3. RIDER_PROFILE
        f.write("-- PERFILES DE RIDER\n")
        for i in range(1, NUM_RIDERS + 1):
            rating = round(random.uniform(3.5, 5.0), 2)
            f.write(f"INSERT INTO RIDER_PROFILE (rider_id, user_id, rating) VALUES ({i}, {i}, {rating});\n")

        f.write("\n")

        # 4. DRIVER_PROFILE
        f.write("-- PERFILES DE DRIVER\n")
        for i in range(1, NUM_DRIVERS + 1):
            user_id = NUM_RIDERS + i
            driver_id = i
            company_id = random.randint(1, NUM_COMPANIES)
            license_num = f"LIC-{random.randint(100000, 999999)}"
            rating = round(random.uniform(4.0, 5.0), 2)
            status = random.choice(['available', 'busy', 'offline'])
            lat, lng = random_lat_lng_madrid()
            
            f.write(f"INSERT INTO DRIVER_PROFILE (driver_id, user_id, company_id, license_number, rating, status, current_lat, current_lng) ")
            f.write(f"VALUES ({driver_id}, {user_id}, {company_id}, {escape(license_num)}, {rating}, {escape(status)}, {lat}, {lng});\n")

        f.write("\n")

        # 5. VEHICLE
        f.write("-- VEHÍCULOS\n")
        for i in range(1, NUM_VEHICLES + 1):
            driver_id = i # Un vehículo por conductor para simplificar
            brand = random.choice(list(BRANDS_MODELS.keys()))
            model = random.choice(BRANDS_MODELS[brand])
            plate = generate_plate()
            year = random.randint(2015, 2024)
            color = random.choice(['Blanco', 'Negro', 'Gris', 'Rojo', 'Azul'])
            category = random.choice(['economy', 'comfort', 'premium'])
            
            f.write(f"INSERT INTO VEHICLE (vehicle_id, driver_id, plate, brand, model, year, color, category) ")
            f.write(f"VALUES ({i}, {driver_id}, {escape(plate)}, {escape(brand)}, {escape(model)}, {year}, {escape(color)}, {escape(category)});\n")

        f.write("\n")

        # 6. TRIPS, OFFERS y PAYMENTS
        f.write("-- VIAJES, OFERTAS Y PAGOS\n")
        offer_id_counter = 1
        payment_id_counter = 1

        for trip_id in range(1, NUM_TRIPS + 1):
            rider_id = random.randint(1, NUM_RIDERS)
            
            orig_lat, orig_lng = random_lat_lng_madrid()
            dest_lat, dest_lng = random_lat_lng_madrid()
            orig_addr = fake.street_address() + ", Madrid"
            dest_addr = fake.street_address() + ", Madrid"

            # Distancia aproximada en KM (fórmula simple euclidiana aproximada para lat/lng en Madrid)
            # 1 grado de lat/lng son ~111km
            dist_km = math.hypot(dest_lat - orig_lat, dest_lng - orig_lng) * 111
            dist_km = round(max(0.5, dist_km), 2)
            
            price_estimated = round(dist_km * 1.50 + 2.0, 2) # 1.50€/km + 2€ base
            
            # Decidir estado del viaje
            status_choices = ['completed']*80 + ['cancelled']*10 + ['in_progress']*5 + ['requested']*5
            status = random.choice(status_choices)

            requested_at = fake.date_time_between(start_date='-3m', end_date='now')
            accepted_at = None
            started_at = None
            finished_at = None
            driver_id = None
            vehicle_id = None
            price_final = None
            duration_mins = None

            num_offers_to_generate = random.randint(1, 5)

            if status == 'requested':
                # Solo ofertas 'pending' o 'expired' o 'rejected', sin conductor asignado
                pass
            
            elif status == 'cancelled':
                # Cancelado antes o después de aceptar. Asumamos 50/50.
                if random.random() < 0.5:
                    # Aceptado y luego cancelado
                    driver_id = random.randint(1, NUM_DRIVERS)
                    vehicle_id = driver_id
                    accepted_at = requested_at + timedelta(minutes=random.uniform(1, 5))
            
            elif status in ['in_progress', 'completed']:
                driver_id = random.randint(1, NUM_DRIVERS)
                vehicle_id = driver_id
                accepted_at = requested_at + timedelta(minutes=random.uniform(1, 5))
                started_at = accepted_at + timedelta(minutes=random.uniform(2, 10))
                
                if status == 'completed':
                    # 1 km -> aprox 2 min (30 km/h) en ciudad
                    duration_mins = int(dist_km * 2) + random.randint(-2, 5)
                    duration_mins = max(1, duration_mins)
                    finished_at = started_at + timedelta(minutes=duration_mins)
                    price_final = round(price_estimated * random.uniform(0.9, 1.1), 2)
            
            # Generar Offers para este viaje
            offers = []
            drivers_offered = random.sample(range(1, NUM_DRIVERS + 1), min(num_offers_to_generate, NUM_DRIVERS))
            
            # Si hay un driver_id asignado al viaje, DEBE estar en las ofertas y DEBE haber aceptado
            if driver_id is not None and driver_id not in drivers_offered:
                drivers_offered[0] = driver_id

            accepted_generated = False
            for d_id in drivers_offered:
                offer_status = 'rejected'
                responded_at = requested_at + timedelta(seconds=random.randint(10, 60))
                
                if d_id == driver_id and not accepted_generated:
                    offer_status = 'accepted'
                    responded_at = accepted_at
                    accepted_generated = True
                else:
                    offer_status = random.choice(['rejected', 'expired'])
                    if offer_status == 'expired':
                        responded_at = None

                offers.append({
                    'id': offer_id_counter,
                    'trip_id': trip_id,
                    'driver_id': d_id,
                    'status': offer_status,
                    'sent_at': requested_at + timedelta(seconds=random.randint(1, 5)),
                    'responded_at': responded_at
                })
                offer_id_counter += 1

            # ESCRIBIR TRIP
            f.write(f"INSERT INTO TRIP (trip_id, rider_id, driver_id, vehicle_id, origin_lat, origin_lng, origin_address, dest_lat, dest_lng, dest_address, status, distance_km, duration_minutes, price_estimated, price_final, requested_at, accepted_at, started_at, finished_at) ")
            f.write(f"VALUES ({trip_id}, {rider_id}, {escape(driver_id)}, {escape(vehicle_id)}, {orig_lat}, {orig_lng}, {escape(orig_addr)}, {dest_lat}, {dest_lng}, {escape(dest_addr)}, {escape(status)}, {escape(dist_km)}, {escape(duration_mins)}, {escape(price_estimated)}, {escape(price_final)}, {format_dt(requested_at)}, {format_dt(accepted_at)}, {format_dt(started_at)}, {format_dt(finished_at)});\n")

            # ESCRIBIR OFFERS
            for off in offers:
                f.write(f"INSERT INTO OFFER (offer_id, trip_id, driver_id, status, sent_at, responded_at) ")
                f.write(f"VALUES ({off['id']}, {off['trip_id']}, {off['driver_id']}, {escape(off['status'])}, {format_dt(off['sent_at'])}, {format_dt(off['responded_at'])});\n")

            # ESCRIBIR PAYMENT (Solo si completado)
            if status == 'completed':
                platform_fee = round(price_final * 0.20, 2)
                driver_earnings = round(price_final * 0.80, 2)
                method = random.choice(['card', 'card', 'cash', 'wallet'])
                payment_status = random.choice(['completed', 'completed', 'pending'])
                
                paid_at = finished_at + timedelta(minutes=random.randint(0, 5)) if payment_status == 'completed' else None
                
                f.write(f"INSERT INTO PAYMENT (payment_id, trip_id, amount, platform_fee, driver_earnings, method, status, paid_at) ")
                f.write(f"VALUES ({payment_id_counter}, {trip_id}, {price_final}, {platform_fee}, {driver_earnings}, {escape(method)}, {escape(payment_status)}, {format_dt(paid_at)});\n")
                payment_id_counter += 1
            
            # Un salto de línea extra cada 10 viajes para limpieza visual
            if trip_id % 10 == 0:
                f.write("\n")

        f.write("SET FOREIGN_KEY_CHECKS = 1;\n")
        
    print("¡Archivo data.sql generado con éxito!")

if __name__ == "__main__":
    run()
