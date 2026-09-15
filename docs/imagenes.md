    Aqui podemos encontrar las imagenes usadas, su tamaño y su proposito:

    IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
    hello-world:latest   5e2309035332       25.9kB         9.49kB
    nginx:1.30-alpine    dc5069ad14f1        102MB         29.4MB    U
    postgres:18-alpine   d3e1620b530c        433MB          121MB    U

    postgres:18-alpine: Su propósito es actuar como el motor de base de datos relacional de la solución. Se encarga del almacenamiento persistente de los datos de la aplicación, procesando de forma segura las consultas e inserciones que realice la API backend.

    nginx:1.30-alpine: Su propósito es actuar como el proxy inverso y único punto de entrada expuesto al exterior de la infraestructura. Se encarga de recibir las peticiones de los clientes (puerto 8080) y enrutarlas internamente hacia el servicio de la API, aislando el resto de los componentes por seguridad.

    hello-world:latest: Su propósito es puramente de diagnóstico y verificación inicial. Sirve para confirmar que el motor de Docker Engine se instaló correctamente y tiene los permisos necesarios para comunicarse con el Registry (Docker Hub), descargar imágenes y ejecutar contenedores sin problemas.

