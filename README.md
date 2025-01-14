# AutoMoodle

AutoMoodle es un script Bash diseñado para la instalación y configuración automática de Moodle, el popular sistema de gestión de aprendizaje (LMS). Este script permite configurar de manera rápida un entorno funcional con las mejores prácticas de Moodle, incluyendo soporte para HTTPS, ajustes de PHP, y configuración de base de datos.

---

## Características
- **Instalación automática de Moodle** en la última versión disponible.
- Configuración compatible con **Apache2**.
- Instalación y configuración de **PHP 8.1** y extensiones necesarias.
- **Soporte de HTTPS** mediante Let's Encrypt.
- Configuración de base de datos MySQL o PostgreSQL.
- Ajustes recomendados de PHP para **Moodle**, como:
  - `max_input_vars = 5000`
  - `opcache.enable = 1`
  - `memory_limit = 128M`

---

## Requisitos previos
- Un sistema operativo basado en **Ubuntu 22.04** o superior.
- Acceso como usuario root o con privilegios de `sudo`.
- Un nombre de dominio apuntando al servidor.
- Conexión a internet para descargar paquetes y certificar HTTPS.

---

## Instalación

1. **Clona el repositorio**:
    ```bash
    git clone https://github.com/linoreki/AutoMoodle.git
    cd AutoMoodle
    ```

2. **Haz ejecutable el script**:
    ```bash
    chmod +x automoodle.sh
    ```

3. **Ejecuta el script**:
    ```bash
    sudo ./automoodle.sh
    ```

---

## Configuración del script

El script solicitará los siguientes datos durante la ejecución:

- **Dominio o IP:** El nombre de dominio para acceder al sitio Moodle.
- **Ruta de instalación:** La carpeta en la que se instalará Moodle (por defecto: `/var/www/moodle`).
- **Puerto del servidor:** El puerto en el que se hosteará el sitio (por defecto: `80`).
- **Versión de PHP:** Versión de PHP a instalar (por defecto: `8.1`).
- **Base de datos:** Tipo de base de datos a usar (`mariadb`, `mysql` o `postgres`).
- **Credenciales de la base de datos:** Nombre, usuario y contraseña de la base de datos.

---

## Qué hace el script

1. Instala los paquetes necesarios:
   - **Apache2** como servidor web.
   - **PHP** y las extensiones requeridas para Moodle.
   - **MySQL** o **PostgreSQL** según tu elección.
2. Descarga y configura Moodle.
3. Crea y configura la base de datos.
4. Aplica los ajustes recomendados para optimizar el entorno Moodle.
5. Configura automáticamente HTTPS usando **Let's Encrypt**.
6. Genera un archivo temporal `info.php` para verificar la configuración PHP.

---

## Uso del sitio Moodle

Después de completar la instalación, el script mostrará la URL de acceso a Moodle. 

Inicia sesión como administrador con las credenciales configuradas durante el proceso de instalación.

---

## Problemas comunes
### Problema: `max_input_vars` no está configurado correctamente
Si la configuración de `max_input_vars` no se refleja, verifica manualmente el archivo `php.ini` siguiendo estos pasos:
1. Abre `info.php` en tu navegador (`http://tudominio.com/info.php`).
2. Encuentra el archivo `php.ini` cargado y ajusta la configuración según se necesite.

---

## Contribuir

¡Las contribuciones son bienvenidas! Si tienes ideas para mejorar el script:
1. Haz un fork del repositorio.
2. Crea una rama para tu función o corrección: `git checkout -b mi-nueva-funcion`.
3. Realiza tus cambios y haz commit: `git commit -am 'Agrega una nueva función'`.
4. Envía un pull request.

---

## Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo [LICENSE](./LICENSE) para obtener más información.

---

## Créditos

Este script fue desarrollado por [linoreki](https://github.com/linoreki) como una solución automatizada para instalar Moodle de manera sencilla y eficiente.
