# Manual técnico

## 1. Descripción de la solución

La solución corresponde a una aplicación web desplegada mediante contenedores Docker.

La arquitectura está compuesta por tres servicios principales:

* **Proxy:** Nginx, encargado de recibir las solicitudes HTTP desde el exterior y dirigirlas hacia la API.
* **API:** aplicación desarrollada con FastAPI y ejecutada mediante Uvicorn.
* **Base de datos:** PostgreSQL, utilizada para almacenar los datos de la aplicación.

Los servicios se administran mediante Docker Compose y se conectan mediante una red interna de Docker.

La arquitectura general es:

```text
                    Usuario
                       │
                       │ HTTP :80
                       ▼
              ┌─────────────────┐
              │      Nginx      │
              │     proxy       │
              └────────┬────────┘
                       │
                       │ HTTP :8000
                       ▼
              ┌─────────────────┐
              │       API       │
              │     FastAPI     │
              └────────┬────────┘
                       │
                       │ PostgreSQL :5432
                       ▼
              ┌─────────────────┐
              │   PostgreSQL    │
              │       DB        │
              └─────────────────┘

              Red interna Docker
                  red-interna
```

La base de datos no se publica directamente hacia el host. El acceso externo se realiza únicamente mediante el proxy Nginx.

---

## 2. Componentes de la arquitectura

### 2.1 Nginx

Nginx funciona como proxy inverso.

Su función es recibir las solicitudes HTTP realizadas al puerto 80 del host y reenviarlas hacia la API mediante el nombre del servicio Docker:

```text
http://api:8000
```

La configuración se encuentra en:

```text
nginx/default.conf
```

La configuración utilizada es:

```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://api:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

### 2.2 API

La API está desarrollada con FastAPI y utiliza Uvicorn como servidor de aplicaciones.

El código principal se encuentra en:

```text
app/main.py
```

La aplicación proporciona, entre otras, las siguientes rutas:

```text
GET /health
GET /db
```

La ruta `/health` permite comprobar que la API está funcionando.

La ruta `/db` permite comprobar la conexión entre la API y PostgreSQL.

La imagen de la API se construye mediante el archivo:

```text
Dockerfile
```

---

### 2.3 PostgreSQL

PostgreSQL funciona dentro de un contenedor independiente.

La base de datos no tiene una sección `ports` en Docker Compose, por lo que el puerto 5432 no se publica directamente en el host.

La API accede a PostgreSQL utilizando el nombre del servicio:

```text
db
```

y el puerto interno:

```text
5432
```

---

## 3. Puertos

La solución utiliza los siguientes puertos:

| Servicio   | Puerto interno | Puerto publicado | Función              |
| ---------- | -------------: | ---------------: | -------------------- |
| Nginx      |             80 |               80 | Entrada HTTP         |
| API        |           8000 |     No publicado | Comunicación interna |
| PostgreSQL |           5432 |     No publicado | Comunicación interna |

El único puerto publicado hacia el host es:

```text
80
```

Por esta razón, los clientes externos acceden a la aplicación mediante:

```text
http://localhost
```

La API y PostgreSQL se comunican internamente mediante la red Docker.

---

## 4. Red Docker

Los tres servicios utilizan la red:

```text
red-interna
```

La red está definida en `docker-compose.yml`:

```yaml
networks:
  red-interna:
    driver: bridge
```

Los servicios conectados a esta red son:

```text
proxy
api
db
```

Docker Compose permite que los servicios se comuniquen utilizando sus nombres de servicio.

Por ejemplo, la API utiliza:

```text
DB_HOST=db
```

para localizar el contenedor PostgreSQL.

De esta manera no es necesario utilizar una dirección IP fija.

---

## 5. Persistencia de datos

PostgreSQL utiliza un volumen Docker denominado:

```text
pgdata
```

El volumen se declara en `docker-compose.yml`:

```yaml
volumes:
  pgdata:
```

El servicio de base de datos utiliza este volumen:

```yaml
volumes:
  - pgdata:/var/lib/postgresql
```

El volumen permite conservar los datos de PostgreSQL aunque los contenedores sean detenidos y posteriormente iniciados nuevamente.

La persistencia fue comprobada creando información en la base de datos, ejecutando:

```bash
docker compose down
docker compose up -d
```

y verificando posteriormente que la información continuara disponible.

> No se debe utilizar `docker compose down -v` durante una prueba de persistencia, porque este comando elimina los volúmenes asociados al proyecto.

---

## 6. Variables de entorno

Las credenciales y datos de conexión de PostgreSQL se proporcionan mediante variables de entorno.

Las principales variables utilizadas son:

| Variable            | Utilización                                            |
| ------------------- | ------------------------------------------------------ |
| `POSTGRES_DB`       | Nombre de la base de datos                             |
| `POSTGRES_USER`     | Usuario de PostgreSQL                                  |
| `POSTGRES_PASSWORD` | Contraseña de PostgreSQL                               |
| `DB_HOST`           | Host utilizado por la API para conectarse a PostgreSQL |
| `DB_NAME`           | Nombre de la base de datos utilizada por la API        |
| `DB_USER`           | Usuario utilizado por la API                           |
| `DB_ADMIN_PASSWORD` | Contraseña utilizada por la API                        |

La configuración sensible no debe almacenarse directamente dentro del código fuente.

El archivo `.env`, cuando se utiliza para proporcionar estas variables, debe mantenerse fuera del control de versiones.

---

## 7. Docker Compose

La orquestación de los servicios se encuentra en:

```text
docker-compose.yml
```

La solución puede levantarse utilizando:

```bash
docker compose up -d
```

Para comprobar el estado de los contenedores:

```bash
docker compose ps
```

Para detener los servicios:

```bash
docker compose down
```

Para consultar los registros:

```bash
docker compose logs
```

También pueden consultarse los registros de un servicio específico:

```bash
docker compose logs api
docker compose logs db
docker compose logs proxy
```

---

## 8. Procedimiento de instalación y despliegue local

### Paso 1. Clonar el repositorio

Desde el equipo donde se realizará el despliegue:

```bash
git clone https://github.com/Jeison753/infraestructura-docker-app.git
cd infraestructura-docker-app
```

### Paso 2. Configurar las variables de entorno

Crear el archivo `.env` con las variables requeridas por Docker Compose.

Las credenciales reales no deben incluirse en el repositorio.

### Paso 3. Construir y levantar la solución

Ejecutar:

```bash
docker compose up -d --build
```

### Paso 4. Verificar los servicios

Ejecutar:

```bash
docker compose ps
```

Los servicios esperados son:

```text
api-app
db-app
proxy-app
```

### Paso 5. Verificar la API

Comprobar el endpoint de salud:

```bash
curl http://localhost/health
```

La respuesta esperada es:

```json
{"status":"ok"}
```

### Paso 6. Verificar la conexión con la base de datos

Ejecutar:

```bash
curl http://localhost/db
```

La respuesta debe indicar que la base de datos está conectada.

### Paso 7. Verificar la persistencia

La persistencia se comprueba mediante la creación de datos, el reinicio de los servicios y la posterior consulta de la información almacenada.

### Paso 8. Detener la solución

Para detener los contenedores:

```bash
docker compose down
```

---

## 9. Verificación de aislamiento de PostgreSQL

La base de datos no publica el puerto 5432 hacia el host.

La comprobación se puede realizar mediante:

```bash
docker compose port db 5432
```

El resultado esperado indica que no existe un puerto publicado.

También puede verificarse desde el host:

```bash
curl --max-time 3 http://localhost:5432 || echo "correcto: la BD no responde desde el host"
```

El acceso a PostgreSQL debe realizarse desde los servicios que forman parte de la red interna Docker.

---

## 10. Publicación de la imagen Docker

La imagen de la API también se publica en GitHub Container Registry (GHCR).

El repositorio de imágenes es:

```text
ghcr.io/Jeison753/infraestructura-docker-app
```

La publicación puede realizarse manualmente mediante Docker o automáticamente mediante GitHub Actions.

El workflow de publicación se encuentra en:

```text
.github/workflows/publicar-imagen.yml
```

El workflow construye la imagen y la publica automáticamente cuando se realiza un `push` sobre `main` o cuando se crea un tag de versión con el formato:

```text
v*.*.*
```

Las imágenes pueden identificarse mediante etiquetas como:

```text
latest
sha-<commit>
1.0.0
```

Para obtener información detallada sobre este proceso consultar:

```text
docs/despliegue-automatizado.md
```

---

## 11. Arquitectura de despliegue remoto

La misma solución puede trasladarse a un servidor remoto que disponga de Ubuntu y Docker Engine.

El procedimiento general es:

```text
GitHub
   │
   ▼
Servidor Ubuntu
   │
   ▼
Docker Engine
   │
   ▼
Docker Compose
   │
   ├── Nginx
   ├── API
   └── PostgreSQL
```

En un despliegue remoto se deben considerar especialmente:

* Puerto asignado por el servidor.
* Configuración de las variables de entorno.
* Protección de las credenciales.
* Persistencia del volumen de PostgreSQL.
* Acceso SSH.
* Disponibilidad del servicio.
* Uso de una versión específica de la imagen.

El despliegue remoto se realizará únicamente cuando el servidor y las credenciales correspondientes sean proporcionados y habilitados por el instructor.

---

## 12. Propuesta de escalamiento y transferencia

### 12.1 Diferencias entre el despliegue local y remoto

En el entorno local la aplicación se ejecuta en el equipo del aprendiz utilizando Docker Engine y Docker Compose. El acceso se realiza mediante `localhost` y el puerto 80.

En un servidor remoto, los contenedores se ejecutarían en una máquina Ubuntu con Docker Engine. El acceso se realizaría mediante la dirección o dominio asignado al servidor y el puerto habilitado para la aplicación.

Las rutas internas de Docker se mantienen conceptualmente iguales, ya que los servicios continúan comunicándose mediante la red interna y los nombres definidos por Docker Compose.

La principal diferencia corresponde al entorno de ejecución, los puertos expuestos, las credenciales de acceso y las condiciones de disponibilidad.

### 12.2 Secretos

En el entorno local las variables de configuración pueden proporcionarse mediante un archivo `.env` que no debe ser incluido en el repositorio.

En un entorno remoto se recomienda administrar las credenciales mediante mecanismos seguros de gestión de secretos o variables protegidas del entorno de despliegue.

Las claves SSH y demás credenciales no deben almacenarse en archivos versionados.

### 12.3 Disponibilidad

El entorno local depende de que el equipo del aprendiz permanezca encendido y de que Docker Engine esté funcionando.

En un servidor remoto se puede disponer de una infraestructura con mayor disponibilidad, monitoreo, copias de seguridad y mecanismos de recuperación.

### 12.4 Componentes que podrían trasladarse a la nube

En un escenario productivo se podría trasladar la aplicación a una infraestructura cloud.

La API podría ejecutarse en un servicio de contenedores administrado, mientras que PostgreSQL podría utilizar un servicio administrado de base de datos.

El almacenamiento de datos debería utilizar mecanismos persistentes y respaldos periódicos.

El uso de servicios administrados permitiría reducir la administración directa del sistema operativo y facilitar tareas como disponibilidad, respaldo, monitoreo y escalamiento.

### 12.5 Protección de datos personales

Si la aplicación almacena información asociada a personas, el tratamiento de dichos datos debe realizarse considerando las obligaciones aplicables de protección de datos personales, incluida la Ley 1581 de 2012.

Se deben considerar medidas como:

* Proteger las credenciales de acceso.
* Limitar el acceso a la información.
* Evitar almacenar datos personales innecesarios.
* Mantener mecanismos adecuados de respaldo y recuperación.
* Proteger la información durante su transmisión.
* Definir quién puede acceder a la información almacenada.
* Gestionar adecuadamente los datos cuando ya no sean necesarios.

La implementación concreta de estas medidas debe ajustarse al tipo de información procesada y a los requisitos aplicables al entorno donde se despliegue la solución.

---

## 13. Mantenimiento

Para actualizar la aplicación se debe obtener la nueva versión del código o imagen y posteriormente reconstruir o actualizar los servicios.

En un despliegue basado en Docker Compose puede utilizarse:

```bash
docker compose pull
docker compose up -d
```

Cuando sea necesario reconstruir la imagen local:

```bash
docker compose up -d --build
```

Se recomienda verificar posteriormente:

```bash
docker compose ps
```

y comprobar:

```bash
curl http://localhost/health
```

---

## 14. Archivos principales del proyecto

La estructura relevante del proyecto es:

```text
infraestructura-docker-app/
├── app/
│   └── main.py
├── docs/
│   ├── despliegue-automatizado.md
│   ├── manual-tecnico.md
│   └── pruebas.md
├── nginx/
│   └── default.conf
├── .github/
│   └── workflows/
│       └── publicar-imagen.yml
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
└── README.md
```

Cada archivo cumple una función específica dentro de la solución:

* `app/main.py`: código de la API.
* `Dockerfile`: construcción de la imagen de la API.
* `docker-compose.yml`: definición y orquestación de los servicios.
* `nginx/default.conf`: configuración del proxy inverso.
* `.github/workflows/publicar-imagen.yml`: publicación automática de la imagen.
* `docs/pruebas.md`: evidencias de las pruebas realizadas.
* `docs/despliegue-automatizado.md`: documentación del proceso de publicación automática.
* `docs/manual-tecnico.md`: documentación técnica de la solución.
* `README.md`: información general e instrucciones iniciales del proyecto.
