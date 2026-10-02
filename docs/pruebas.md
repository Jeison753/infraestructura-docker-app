# Pruebas de validación – Semana 5

## 1. Objetivo

Validar el funcionamiento de la solución Dockerizada, comprobando el acceso de la API, la comunicación interna con PostgreSQL, la persistencia de los datos y el aislamiento de la base de datos frente al host.

## 2. Estado inicial de los servicios

Se ejecutó:

```bash
docker compose ps
```

Resultado: los servicios `api-app`, `db-app` y `proxy-app` quedaron en estado `Up`.

La aplicación quedó disponible mediante el proxy Nginx en el puerto `80`.

## 3. Prueba de salud de la API

Comando:

```bash
curl -i http://localhost/health
```

Resultado:

```text
HTTP/1.1 200 OK
Content-Type: application/json
```

Respuesta:

```json
{"status":"ok"}
```

**Resultado: APROBADA.**

La API responde correctamente a través del proxy Nginx.

## 4. Prueba de comunicación API → PostgreSQL

Comando:

```bash
curl -i http://localhost/db
```

Resultado:

```json
{"db":"conectada","version":"PostgreSQL 18.6 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit"}
```

**Resultado: APROBADA.**

La API puede conectarse correctamente al servicio PostgreSQL mediante la red interna de Docker.

También se verificó la resolución DNS interna mediante:

```bash
docker compose exec api python -c "import socket; print(socket.gethostbyname('db'))"
```

Resultado:

```text
172.19.0.2
```

Esto confirma que el servicio `api` puede resolver el nombre `db` dentro de la red Docker.

## 5. Prueba de persistencia de datos

Se creó una tabla de prueba en PostgreSQL y se almacenó el registro:

```text
dato-semana-5
```

Posteriormente se ejecutó:

```bash
docker compose down
```

y después:

```bash
docker compose up -d
```

Los tres servicios volvieron a iniciar correctamente.

Finalmente se consultó nuevamente la tabla:

```sql
SELECT * FROM prueba_persistencia;
```

Resultado:

```text
 id |    mensaje
----+---------------
  1 | dato-semana-5
```

**Resultado: APROBADA.**

El dato sobrevivió al ciclo de detención y posterior inicio de los contenedores, demostrando la persistencia mediante el volumen de PostgreSQL.

## 6. Prueba de aislamiento de PostgreSQL

Se verificó que PostgreSQL no tiene un puerto publicado hacia el host mediante:

```bash
docker compose port db 5432
```

Resultado:

```text
:0
```

También se ejecutó:

```bash
curl --max-time 3 http://localhost:5432 || echo "correcto: la BD no responde desde el host"
```

Resultado:

```text
correcto: la BD no responde desde el host
```

**Resultado: APROBADA.**

PostgreSQL permanece accesible para los servicios de la red interna de Docker, pero no tiene un puerto publicado directamente hacia el host.

## 7. Resumen de validaciones

| Validación                        | Resultado |
| --------------------------------- | --------- |
| Inicio de los servicios           | APROBADA  |
| API `/health`                     | APROBADA  |
| Comunicación API → PostgreSQL     | APROBADA  |
| Resolución DNS interna `api → db` | APROBADA  |
| Persistencia de datos             | APROBADA  |
| Aislamiento de PostgreSQL         | APROBADA  |

## 8. Conclusión

La solución Dockerizada fue validada correctamente. Los servicios se inician mediante Docker Compose, la API responde a través del proxy Nginx, la comunicación con PostgreSQL funciona mediante la red interna, los datos persisten después de reiniciar los servicios y PostgreSQL no expone directamente su puerto al host.
