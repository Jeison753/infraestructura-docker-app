    Aqui podemos encontrar las imagenes usadas, su tamaño y su proposito:

    IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
    hello-world:latest   5e2309035332       25.9kB         9.49kB
    nginx:1.30-alpine    dc5069ad14f1        102MB         29.4MB    U
    postgres:18-alpine   d3e1620b530c        433MB          121MB    U

    postgres:18-alpine: Su propósito es actuar como el motor de base de datos relacional de la solución. Se encarga del almacenamiento persistente de los datos de la aplicación, procesando de forma segura las consultas e inserciones que realice la API backend.

    nginx:1.30-alpine: Su propósito es actuar como el proxy inverso y único punto de entrada expuesto al exterior de la infraestructura. Se encarga de recibir las peticiones de los clientes (puerto 8080) y enrutarlas internamente hacia el servicio de la API, aislando el resto de los componentes por seguridad.

    hello-world:latest: Su propósito es puramente de diagnóstico y verificación inicial. Sirve para confirmar que el motor de Docker Engine se instaló correctamente y tiene los permisos necesarios para comunicarse con el Registry (Docker Hub), descargar imágenes y ejecutar contenedores sin problemas.
    
    
# Administración y ciclo de vida de las imágenes Docker

## Imágenes utilizadas

Aquí podemos encontrar las imágenes usadas, su tamaño y su propósito:

| IMAGE | ID | DISK USAGE | CONTENT SIZE | EXTRA |
|---|---|---:|---:|---|
| hello-world:latest | 5e2309035332 | 25.9kB | 9.49kB | |
| nginx:1.30-alpine | dc5069ad14f1 | 102MB | 29.4MB | U |
| postgres:18-alpine | d3e1620b530c | 433MB | 121MB | U |

**postgres:18-alpine:** Su propósito es actuar como el motor de base de datos relacional de la solución. Se encarga del almacenamiento persistente de los datos de la aplicación, procesando de forma segura las consultas e inserciones que realice la API backend.

**nginx:1.30-alpine:** Su propósito es actuar como el proxy inverso y único punto de entrada expuesto al exterior de la infraestructura. Se encarga de recibir las peticiones de los clientes (puerto 8080) y enrutarlas internamente hacia el servicio de la API, aislando el resto de los componentes por seguridad.

**hello-world:latest:** Su propósito es puramente de diagnóstico y verificación inicial. Sirve para confirmar que el motor de Docker Engine se instaló correctamente y tiene los permisos necesarios para comunicarse con el Registry (Docker Hub), descargar imágenes y ejecutar contenedores sin problemas.

## Imagen de la API

Para la construcción de la API se utilizó un Dockerfile basado en una estrategia de construcción multi-etapa (multi-stage build). La imagen generada fue etiquetada con la versión `1.0.0` y posteriormente con la etiqueta `latest`.

### Etiquetado de la imagen

Se utilizó el siguiente comando:

```bash
docker tag api-app:1.0.0 api-app:latest
```

Esto permite disponer de una etiqueta estable (`latest`) además de la versión específica `1.0.0`.

### Inspección de las capas

Para inspeccionar las capas de la imagen se utilizó:

```bash
docker history api-app:1.0.0
```

En la imagen multi-etapa se observa que la instalación de dependencias se realiza en la etapa `builder` y posteriormente los archivos instalados se copian a la imagen final mediante:

```text
COPY /install /usr/local
```

Esta separación evita trasladar a la imagen final los elementos intermedios propios de la etapa de construcción.

También se verificó que la imagen final utiliza el usuario no root `appuser`, mediante la instrucción:

```text
USER appuser
```

### Tamaño de la imagen

El tamaño registrado para la imagen construida fue:

| Imagen | DISK USAGE | CONTENT SIZE |
|---|---:|---:|
| `api-app:1.0.0` | 263 MB | 63.6 MB |

### Comparación con una imagen sin multi-etapa

Para realizar la comparación solicitada se construyó temporalmente una imagen equivalente utilizando un Dockerfile de una sola etapa:

| Imagen | DISK USAGE | CONTENT SIZE |
|---|---:|---:|
| `api-app:1.0.0` — multi-stage | 263 MB | 63.6 MB |
| `api-app:single` — single-stage | 263 MB | 63.6 MB |

En esta prueba concreta no se presentó una diferencia de tamaño entre ambas imágenes. Esto se debe a que las dos utilizan como base `python:3.14-slim` y la instalación de dependencias se realizó utilizando `pip install --no-cache-dir`, por lo que la imagen de una sola etapa tampoco conservó la caché de instalación.

Sin embargo, la inspección mediante `docker history` evidencia una diferencia en la organización de la construcción. En la imagen multi-etapa la instalación se realiza en una etapa `builder` y posteriormente se copia el contenido instalado a la imagen final:

```text
COPY /install /usr/local    56.8MB
```

En la imagen de una sola etapa, la instalación aparece directamente como una capa de la imagen final:

```text
RUN /bin/sh -c pip install --no-cache-dir -r...    56.8MB
```

Por lo tanto, aunque en esta comparación el tamaño final fue igual, el enfoque multi-stage mantiene separada la etapa de construcción de la etapa final y permite controlar qué artefactos pasan a la imagen de ejecución.

### Eliminación de imágenes no utilizadas

Como práctica de administración del ciclo de vida, se creó temporalmente una etiqueta de prueba para la imagen de la API:

```bash
docker tag api-app:1.0.0 api-app:prueba-eliminar
```

Posteriormente se eliminó dicha etiqueta mediante:

```bash
docker rmi api-app:prueba-eliminar
```

Se evitó eliminar imágenes pertenecientes a otros proyectos o imágenes necesarias para la práctica.

### Espacio ocupado por Docker

Para medir el espacio utilizado por Docker se ejecutó:

```bash
docker system df
```

El resultado obtenido fue:

| Tipo | Total | Activo | Tamaño | Reclamable |
|---|---:|---:|---:|---:|
| Images | 12 | 4 | 2.975 GB | 1.314 GB (44%) |
| Containers | 4 | 1 | 32.77 kB | 28.67 kB (87%) |
| Local Volumes | 5 | 1 | 390.9 MB | 342.5 MB (87%) |
| Build Cache | 47 | 0 | 756.4 MB | 197.3 MB |

Estos datos permiten identificar el consumo actual de almacenamiento de Docker y los recursos que pueden ser recuperados mediante tareas de limpieza cuando sea necesario.

## Comprobación de la API

La imagen `api-app:1.0.0` fue ejecutada como contenedor y se verificó el funcionamiento del servicio mediante el endpoint:

```bash
curl http://localhost:8000/health
```

La respuesta obtenida fue:

```json
{"status":"ok"}
```

También se verificó que la aplicación se ejecuta con el usuario no privilegiado definido en el Dockerfile:

```bash
docker exec api-app whoami
```

Resultado esperado y obtenido:

```text
appuser
```

Con estas comprobaciones se evidencia la construcción, versionado, inspección, ejecución y administración básica del ciclo de vida de la imagen Docker de la API.

