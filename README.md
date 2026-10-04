# infraestructura-docker-app

Repositorio para el despliegue y uso de Docker de una aplicación web compuesta por Nginx, FastAPI y PostgreSQL.

## 1. Descripción del proyecto

El proyecto implementa una aplicación web contenerizada mediante Docker Compose.

La arquitectura está compuesta por tres servicios principales:

* **Nginx:** actúa como proxy inverso y recibe las solicitudes HTTP.
* **FastAPI:** proporciona la API de la aplicación.
* **PostgreSQL:** almacena los datos de la aplicación.

Los servicios se comunican mediante una red interna de Docker. La base de datos PostgreSQL no publica su puerto directamente al host, por lo que solamente es accesible desde los servicios autorizados dentro de la red Docker.

La solución también incluye un volumen persistente para conservar los datos de PostgreSQL aunque los contenedores sean recreados.

## 2. Requisitos

Para ejecutar el proyecto se requiere:

* Docker
* Docker Compose

Se recomienda utilizar una versión reciente de Docker con soporte para Docker Compose.

## 3. Estructura principal

```text
infraestructura-docker-app/
├── app/
│   └── main.py
├── nginx/
│   └── default.conf
├── docs/
│   ├── despliegue-automatizado.md
│   ├── entorno.md
│   ├── imagenes.md
│   ├── manual-tecnico.md
│   ├── pruebas.md
│   └── requisitos.md
├── .github/
│   └── workflows/
│       └── publicar-imagen.yml
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## 4. Ejecución del proyecto

Levantar los servicios:

```bash
docker compose up -d --build
```

Verificar los contenedores:

```bash
docker compose ps
```

Probar la API:

```bash
curl http://localhost/health
```

Probar la conexión con PostgreSQL:

```bash
curl http://localhost/db
```

Detener los servicios:

```bash
docker compose down
```

## 5. Documentación

La documentación detallada se encuentra en:

* `docs/pruebas.md`
* `docs/despliegue-automatizado.md`
* `docs/manual-tecnico.md`

## 6. Imagen Docker

La imagen se publica mediante GitHub Actions en GitHub Container Registry:

```text
ghcr.io/jeison753/infraestructura-docker-app
```

## 7. Flujo de trabajo Git

La rama utilizada para el desarrollo de esta semana es:

```text
feature/semana-5
```
