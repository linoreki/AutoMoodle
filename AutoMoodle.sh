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

read -p "Versión de PHP requerida (ejemplo: 8.1): " PHP_VERSION
read -p "Base de datos a usar (mariadb/mysql/postgres): " DB_TYPE
read -p "Nombre de la base de datos para Moodle: " DB_NAME
read -p "Usuario de la base de datos: " DB_USER
read -s -p "Contraseña del usuario de la base de datos: " DB_PASSWORD
echo ""

# Instalar paquetes necesarios
echo "=== Instalando dependencias necesarias ==="
apt update && apt install -y nginx php$PHP_VERSION-fpm php$PHP_VERSION-cli \
php$PHP_VERSION-curl php$PHP_VERSION-xml php$PHP_VERSION-mbstring \
php$PHP_VERSION-zip php$PHP_VERSION-mysql mariadb-server git unzip

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

# Configurar NGINX
echo "=== Configurando NGINX ==="
cat > /etc/nginx/sites-available/moodle <<EOL
server {
    listen 80;
    server_name $MOODLE_DOMAIN;

    root $MOODLE_PATH;
    index index.php;

    location / {
        try_files \$uri /index.php;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|otf|eot|ttc|txt|xml|pdf|doc|xls|ppt|zip|tar|tgz|gz|rar|bz2|7z|mp3|ogg|mp4|m4v|webm|ogg|ogv|ico|svg)\$ {
        try_files \$uri /index.php;
        expires max;
        access_log off;
    }
}
EOL

ln -s /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Configurar Moodle
echo "=== Configurando Moodle ==="
php $MOODLE_PATH/admin/cli/install.php --wwwroot="http://$MOODLE_DOMAIN" \
    --dataroot=$MOODLEDATA_PATH --dbtype=$DB_TYPE --dbname=$DB_NAME \
    --dbuser=$DB_USER --dbpass=$DB_PASSWORD --fullname="Moodle Site" \
    --shortname="Moodle" --adminuser=admin --adminpass=Admin123! \
    --agree-license --non-interactive

echo "=== Moodle instalado exitosamente ==="
echo "Accede a tu sitio en: http://$MOODLE_DOMAIN"
