# Matriz de Requisitos de Infraestructura

| # | Requisito de infraestructura | Criterio de aceptación |
|---|---|---|
| RI-01 | Los tres servicios se ejecutan en contenedores independientes. | `docker compose ps` muestra tres servicios en estado `up`. |
| RI-02 | Solo el proxy inverso está expuesto al exterior. | El servicio de base de datos no tiene sección `ports` y no responde desde el host. |
| RI-03 | Los datos de la base persisten a los reinicios. | Tras `down` y `up`, la información sigue disponible. |
| RI-04 | La solución opera con 4 GB de memoria RAM. | `docker stats` no supera ese consumo con los tres servicios arriba. |
| RI-05 | La configuración sensible no está escrita en el código. | Las credenciales llegan por variables de entorno; el archivo `.env` no está versionado. |
| RI-OS-01 | La solución debe comportarse igual en Windows y Linux. | El despliegue funciona nativamente en Ubuntu y en WSL2. |

# Componentes de Hardware y Software

| Componente | Imagen base | Puerto interno | Requisito clave |
|---|---|---|---|
| Proxy inverso | `nginx:1.30-alpine` | 80 | Enrutar las peticiones a la API |
| API backend | `python:3.14-slim` | 8000 | Conexión a la base de datos |
| Base de datos | `postgres:18-alpine` | 5432 | Almacenamiento persistente (volumen) |
