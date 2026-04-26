# 🚖 Ride-Hailing Database System - BBDDA


Este proyecto tiene como objetivo diseñar una base de datos capaz de soportar **alta concurrencia** en escenarios de uso intensivo. El foco principal ha sido garantizar la consistencia de la información durante procesos críticos (como la aceptación simultánea de viajes), mantener la integridad referencial y asegurar una correcta gestión de permisos. Además, hemos incorporado una capa analítica para la monitorización en tiempo real de las métricas de negocio y rendimiento.

---

### 👥 Estructura del Equipo de Trabajo

Para abordar el proyecto de manera integral, nos hemos dividido las tareas en tres áreas principales de responsabilidad:

- **Diseño de la Base de Datos:** Se ha trabajado en la normalización del esquema (alcanzando la 3FN) y en la optimización del rendimiento mediante la implementación de índices estratégicos (especialmente para agilizar las búsquedas espaciales y relaciones clave).
- **Consultas y Seguridad:** Nos hemos encargado de redactar las sentencias CRUD, operaciones analíticas (`JOINs` complejos) y transacciones seguras. Además, hemos aplicado el principio de mínimo privilegio creando usuarios específicos para cada rol del sistema.
- **Docker y Backups:** Hemos configurado la infraestructura en contenedores para facilitar su despliegue, implementado un generador de datos para simulaciones operativas y automatizado un sistema de copias de seguridad lógicas mediante eventos programados.

---

## 📋 Requisitos Previos

La plataforma se despliega utilizando contenedores, por lo que era necesario que contaramos con los siguientes elementos instalados en el entorno de evaluación:

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

---

## 🏗️ Decisiones Clave en la Arquitectura

A lo largo del desarrollo, hemos tomado tres decisiones técnicas fundamentales para el buen funcionamiento del sistema:

1. **Control de Concurrencia mediante Bloqueos Pesimistas:** Hemos utilizado `SELECT ... FOR UPDATE` en el proceso de aceptación de ofertas. Esto garantiza que si múltiples peticiones intentan asignar un mismo viaje en el mismo instante, la base de datos bloquee la fila temporalmente, encolando las transacciones y evitando condiciones de carrera (*Race Conditions*).
2. **Optimización de Consultas Espaciales:** En lugar de crear una tabla hiper-normalizada para la geolocalización, decidimos incrustar las coordenadas directamente en la tabla `TRIP`. Esto reduce drásticamente la necesidad de operaciones `JOIN` y mejora los tiempos de respuesta en consultas intensivas.
3. **Poblado con Datos de Simulación:** Hemos generado un volumen significativo de información (>1.000 viajes, usuarios y vehículos) utilizando algoritmos que respetan la integridad referencial. **No son datos falsos aleatorios**, sino registros generados específicamente para simular entornos operativos reales y poder testear la carga y la analítica.

---

## 🔐 Seguridad y Usuarios de la Base de Datos

Siguiendo las mejores prácticas de administración, no operamos el sistema utilizando el superusuario `root`. Hemos segmentado los accesos creando perfiles dedicados:

| Usuario | Permisos Otorgados | Propósito en el Sistema |
| :--- | :--- | :--- |
| `admin_ridehailing` | `ALL PRIVILEGES` | Administrador de Base de Datos (DBA). Tiene control total sobre el esquema y los datos para tareas de configuración de alto nivel. |
| `app_backend` | `SELECT, INSERT, UPDATE` | Usuario operativo de la aplicación. Solo puede leer y escribir en tablas transaccionales, pero no puede hacer `DROP` ni borrar masivamente. |
| `dashboard_reader` | `SELECT` (Global) | Conexión de solo lectura destinada exclusivamente a Grafana para obtener información sin riesgo de alterarla. |
| `auditor` | `SELECT` (Solo en `AUDIT_LOG`) | Perfil de máxima restricción para tareas de auditoría externa, limitado únicamente a consultar los registros de actividad del sistema. |
| `backup_user` | `SELECT, LOCK TABLES...` | Usuario de mantenimiento encargado de realizar copias de seguridad sin alterar la integridad de los datos. |

---

## 📂 Archivos Entregables

La estructura principal del proyecto entregado es la siguiente:

```text
.
├── 🐳 compose.yml                     # Archivo de orquestación para MariaDB, Grafana y Adminer.
├── 📁 init-scripts/                   # Directorio de auto-ejecución al iniciar el contenedor:
│   ├── 01_schema.sql                  # (DDL) Creación de tablas, relaciones, triggers e índices.
│   ├── 02_data.sql                    # Inyección de los datos generados simulando el entorno real.
│   └── 03_permissions.sql             # (DCL) Creación de perfiles y asignación de privilegios.
├── ⚡ queries.sql                     # Consultas de negocio, CRUD y transacciones concurrentes.
├── 📊 dashboard.sql                   # Consultas de métricas y rendimiento preparadas para Grafana.
├── 💾 backup.sql                      # Sistema de Eventos (Archivado automático y volcado a CSV).
└── 📖 README.md                       # Documentación técnica del proyecto (Este archivo).
```

---

## 🚀 Despliegue del Sistema

El despliegue está completamente automatizado. Para arrancar la infraestructura, abre la terminal en la carpeta principal del proyecto y ejecuta:

```bash
docker compose up -d  
```  

 La primera vez que se lanza el contenedor, MariaDB detectará que la base de datos está vacía. Inmediatamente después, leerá la carpeta `./init-scripts/` y ejecutará de forma ordenada los scripts `01_schema.sql`, `02_data.sql` y `03_permissions.sql`. De esta forma, el servidor queda totalmente configurado, con datos y reglas de seguridad aplicadas automáticamente sin necesitar configuración manual.

---

## 🌍 Acceso a los Servicios

Una vez inicializado el entorno, estos son los puntos de acceso a las distintas herramientas locales:

| Herramienta | URL / Host | Credenciales por Defecto |
| :--- | :--- | :--- |
| **Adminer** (Gestor UI) | [http://localhost:8080](http://localhost:8080) | Servidor: `db` <br> User: `root` <br> Pass: `root` |
| **Grafana** (Visualización) | [http://localhost:3000](http://localhost:3000) | User: `admin` <br> Pass: `admin` |
| **MariaDB** (Conexión para IDE) | `localhost:3306` | User: `root` <br> Pass: `root` |
