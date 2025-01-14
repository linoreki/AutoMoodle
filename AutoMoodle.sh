#!/bin/bash

# Comprobación de permisos
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta el script como usuario root."
  exit 1
fi

echo "=== Instalación Automática de Moodle ==="

# Solicitar información del usuario
read -p "Dominio o IP del servidor (ejemplo: moodle.example.com): " MOODLE_DOMAIN
read -p "Ruta de instalación para Moodle (por defecto: /var/www/moodle): " MOODLE_PATH
MOODLE_PATH=${MOODLE_PATH:-/var/www/moodle}

read -p "Puerto en el que hostear Moodle (por defecto: 80): " HOST_PORT
HOST_PORT=${HOST_PORT:-80}

read -p "Versión de PHP requerida (ejemplo: 8.1): " PHP_VERSION
read -p "Base de datos a usar (mariadb/mysql/postgres): " DB_TYPE
read -p "Nombre de la base de datos para Moodle: " DB_NAME
read -p "Usuario de la base de datos: " DB_USER
read -s -p "Contraseña del usuario de la base de datos: " DB_PASSWORD
echo ""

# Instalar paquetes necesarios
echo "=== Instalando dependencias necesarias ==="

apt update && apt install -y php$PHP_VERSION libapache2-mod-php$PHP_VERSION \
php$PHP_VERSION-cli php$PHP_VERSION-curl php$PHP_VERSION-xml php$PHP_VERSION-mbstring \
php$PHP_VERSION-zip php$PHP_VERSION-mysql mysql-server git unzip apache2
systemctl enable apache2
systemctl enable mysql
systemctl start mysql
systemctl start apache2

# Configuración de la base de datos
echo "=== Configurando la base de datos ==="
if [[ "$DB_TYPE" == "mariadb" || "$DB_TYPE" == "mysql" ]]; then
  mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
elif [[ "$DB_TYPE" == "postgres" ]]; then
  apt install -y postgresql postgresql-contrib
  sudo -u postgres psql <<POSTGRES_SCRIPT
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
POSTGRES_SCRIPT
else
  echo "Base de datos no soportada: $DB_TYPE"
  exit 1
fi

# Descargar Moodle
echo "=== Descargando Moodle ==="
git clone --branch MOODLE_401_STABLE git://git.moodle.org/moodle.git $MOODLE_PATH

# Configurar permisos
echo "=== Configurando permisos ==="
chown -R www-data:www-data $MOODLE_PATH
chmod -R 755 $MOODLE_PATH

# Crear directorio de datos
MOODLEDATA_PATH="/var/moodledata"
mkdir -p $MOODLEDATA_PATH
chown -R www-data:www-data $MOODLEDATA_PATH
chmod -R 755 $MOODLEDATA_PATH

# Configurar Apache2
echo "=== Configurando Apache2 ==="
cat > /etc/apache2/sites-available/moodle.conf <<EOL
<VirtualHost *:$HOST_PORT>
    ServerName $MOODLE_DOMAIN

    DocumentRoot $MOODLE_PATH
    <Directory $MOODLE_PATH>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/moodle_error.log
    CustomLog \${APACHE_LOG_DIR}/moodle_access.log combined

    <Directory $MOODLEDATA_PATH>
        Require all denied
    </Directory>
</VirtualHost>
EOL

a2ensite moodle.conf
a2enmod rewrite
systemctl reload apache2

# Configurar Moodle
echo "=== Configurando Moodle ==="
php $MOODLE_PATH/admin/cli/install.php --wwwroot="http://$MOODLE_DOMAIN:$HOST_PORT" \
    --dataroot=$MOODLEDATA_PATH --dbtype=$DB_TYPE --dbname=$DB_NAME \
    --dbuser=$DB_USER --dbpass=$DB_PASSWORD --fullname="Moodle Site" \
    --shortname="Moodle" --adminuser=admin --adminpass=Admin123! \
    --agree-license --non-interactive

# Imprimir configuración final
echo "=== Moodle instalado exitosamente ==="
echo "Accede a tu sitio en: http://$MOODLE_DOMAIN:$HOST_PORT"
echo "Configuración de la base de datos:"
echo "Tipo de base de datos: $DB_TYPE"
echo "Nombre de la base de datos: $DB_NAME"
echo "Usuario de la base de datos: $DB_USER"
echo "Contraseña de la base de datos: $DB_PASSWORD (protegida)"
