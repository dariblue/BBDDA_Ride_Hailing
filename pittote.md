Ran command: `docker compose down`
Ran command: `docker compose up -d`

¡Qué alivio que por fin haya funcionado! Los servidores de Amazon nunca fallan. 

Para ver tu base de datos y comprobar que todo está en orden, la forma más fácil es usar **Adminer** (la interfaz web que acabamos de levantar):

### 1. Entra desde tu navegador:
👉 **[http://localhost:8080](http://localhost:8080)**

### 2. Introduce estos datos para entrar:
- **Sistema:** MySQL
- **Servidor:** `db`
- **Usuario:** `root`
- **Contraseña:** `root`
- **Base de datos:** `ridehailing`

Una vez dentro, a la izquierda deberías ver todas las tablas que diseñamos (`USER`, `TRIP`, `VEHICLE`, etc.). Eso significará que el script `01-schema.sql` se ejecutó correctamente al arrancar.

### 3. (Opcional) Ver el estado desde la terminal:
Si quieres ver si los contenedores están "vivos":
```bash
docker compose ps
```

¿Logras ver las tablas dentro de Adminer? Si es así, ¡ya tienes el entorno listo para empezar a meter datos de prueba!