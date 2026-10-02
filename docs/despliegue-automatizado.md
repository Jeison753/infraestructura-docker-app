# Despliegue automatizado

## 1. Objetivo

Documentar el proceso de publicación automática de la imagen Docker de la API mediante GitHub Actions y GitHub Container Registry (GHCR).

El flujo implementado permite que, al realizar un `push` sobre la rama `main` o al crear un tag de versión con el formato `v*.*.*`, GitHub Actions construya la imagen Docker y la publique automáticamente en GHCR.

El flujo general es:

```text
Repositorio GitHub
       │
       ▼
   GitHub Actions
       │
       ├── Checkout del código
       ├── Configuración de Docker Buildx
       ├── Autenticación en GHCR
       ├── Generación de tags
       └── Construcción y publicación
              │
              ▼
      GitHub Container Registry
              │
              ▼
ghcr.io/Jeison753/infraestructura-docker-app
```

---

## 2. Publicación manual inicial en GHCR

Antes de automatizar la publicación se realizó una prueba manual para comprobar que la imagen podía ser publicada correctamente en GitHub Container Registry.

La imagen local de la API se etiquetó con:

```bash
docker tag infraestructura-docker-app-api:latest api-app:1.0.0
```

Posteriormente se creó la etiqueta correspondiente al registro:

```bash
docker tag api-app:1.0.0 ghcr.io/Jeison753/infraestructura-docker-app:1.0.0
```

Se realizó la autenticación contra GHCR:

```bash
docker login ghcr.io -u Jeison753
```

Finalmente se publicó la imagen:

```bash
docker push ghcr.io/Jeison753/infraestructura-docker-app:1.0.0
```

Esta publicación permitió comprobar previamente el acceso al registro y la disponibilidad de la imagen.

> Los tokens de acceso utilizados para GHCR no se almacenan en el repositorio ni se incluyen en los archivos del proyecto.

---

## 3. Workflow de GitHub Actions

El archivo utilizado para la publicación automática es:

```text
.github/workflows/publicar-imagen.yml
```

El workflow se ejecuta cuando se realiza un `push` sobre:

* La rama `main`.
* Tags que sigan el formato `v*.*.*`.

El flujo utiliza los siguientes permisos:

```yaml
permissions:
  contents: read
  packages: write
```

El permiso `packages: write` permite que el workflow publique la imagen en GitHub Container Registry.

### Etapas del workflow

El proceso automatizado realiza las siguientes operaciones:

1. Descarga el código del repositorio.
2. Configura Docker Buildx.
3. Inicia sesión en GHCR utilizando `GITHUB_TOKEN`.
4. Genera los metadatos y etiquetas de la imagen.
5. Construye la imagen Docker.
6. Publica la imagen en GHCR.
7. Utiliza la caché de GitHub Actions para optimizar futuras construcciones.

La autenticación se realiza mediante:

```yaml
username: ${{ github.actor }}
password: ${{ secrets.GITHUB_TOKEN }}
```

El token utilizado por el workflow es administrado por GitHub y no se almacena manualmente dentro del repositorio.

---

## 4. Etiquetas de las imágenes

El workflow genera diferentes etiquetas dependiendo del evento que origine la ejecución.

### Rama `main`

Cuando se realiza un `push` sobre la rama principal se genera la etiqueta:

```text
latest
```

También se genera una etiqueta asociada al commit mediante el SHA corto:

```text
sha-<commit>
```

Por ejemplo:

```text
ghcr.io/Jeison753/infraestructura-docker-app:latest
ghcr.io/Jeison753/infraestructura-docker-app:sha-9753f27
```

### Tags de versión

Cuando se crea un tag con formato:

```text
v1.0.0
```

el workflow genera una etiqueta de versión:

```text
1.0.0
```

Esto permite utilizar versiones identificables de la imagen.

---

## 5. Imagen publicada

La imagen se publica en:

```text
ghcr.io/Jeison753/infraestructura-docker-app
```

La publicación automática permite disponer de una imagen actualizada después de cada cambio integrado en `main`.

Las versiones se identifican mediante tags como:

```text
latest
sha-<commit>
1.0.0
```

El uso de etiquetas asociadas al commit o a una versión permite identificar de manera precisa qué código corresponde a una imagen determinada.

---

## 6. Resultado de la ejecución

La ejecución del workflow **Publicar imagen Docker** fue completada correctamente después de configurar el acceso del repositorio al paquete de GHCR.

El workflow realiza correctamente:

```text
Checkout
   ↓
Buildx
   ↓
Login GHCR
   ↓
Metadata
   ↓
Docker Build
   ↓
Push
   ↓
Imagen disponible en GHCR
```

La ejecución puede consultarse desde la sección **Actions** del repositorio:

```text
GitHub
→ Actions
→ Publicar imagen Docker
```

El enlace correspondiente a la ejecución verde debe conservarse como evidencia del proceso de publicación automática.

---

## 7. Secretos y credenciales

El proyecto utiliza mecanismos de autenticación proporcionados por GitHub para la publicación automática.

### GITHUB_TOKEN

El workflow utiliza:

```text
secrets.GITHUB_TOKEN
```

Este token es proporcionado automáticamente por GitHub Actions y se utiliza para autenticarse contra GHCR.

No se debe colocar ningún token personal directamente dentro del archivo:

```text
.github/workflows/publicar-imagen.yml
```

Tampoco se deben almacenar tokens, contraseñas u otras credenciales en el repositorio.

### Despliegue remoto

Para un futuro despliegue en un servidor remoto, las credenciales SSH y demás datos sensibles deben almacenarse como **Secrets** del repositorio y no dentro del código fuente.

Los nombres contemplados para este escenario son:

```text
SERVIDOR_SSH_KEY
SERVIDOR_HOST
SERVIDOR_USUARIO
```

Estos valores solamente deben configurarse si el despliegue remoto es habilitado por el instructor.

---

## 8. Estrategia de despliegue

El flujo automatizado prepara la imagen para ser utilizada posteriormente en un entorno remoto.

El proceso esperado es:

```text
Desarrollador
     │
     ▼
Repositorio GitHub
     │
     ▼
Pull Request
     │
     ▼
main
     │
     ▼
GitHub Actions
     │
     ▼
GHCR
     │
     ▼
Servidor remoto
     │
     ▼
Docker Compose
```

En un servidor remoto se recomienda utilizar una etiqueta inmutable, como:

```text
sha-<commit>
```

o una versión:

```text
1.0.0
```

en lugar de depender exclusivamente de:

```text
latest
```

Esto permite identificar exactamente qué versión de la aplicación se está ejecutando.

---

## 9. Rollback

En caso de que una nueva versión presente problemas, el procedimiento de recuperación consiste en utilizar una imagen previamente publicada e identificada mediante su SHA o número de versión.

Por ejemplo:

```text
ghcr.io/Jeison753/infraestructura-docker-app:sha-<commit>
```

o:

```text
ghcr.io/Jeison753/infraestructura-docker-app:1.0.0
```

El servidor remoto puede volver a utilizar una versión anterior mediante la actualización de la referencia de imagen utilizada por el despliegue.

La utilización de tags asociados a commits o versiones facilita la identificación y recuperación de una versión anterior.

---

## 10. Conclusión

La publicación de la imagen Docker fue validada inicialmente de forma manual mediante GHCR y posteriormente automatizada mediante GitHub Actions.

La solución cuenta con un workflow que construye y publica la imagen automáticamente, utiliza `GITHUB_TOKEN` para la autenticación y genera etiquetas que permiten identificar las imágenes por rama, commit y versión.

Con este proceso se establece la integración entre el repositorio GitHub, GitHub Actions y GitHub Container Registry, dejando preparada la solución para su posterior despliegue en un servidor remoto cuando este sea habilitado.
