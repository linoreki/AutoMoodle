#!/bin/bash

# Verificar si el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit
fi

echo "=== Instalación de Moodle ==="

# Solicitar el nombre de usuario y la contraseña de la base de datos
read -p "Introduce el nombre de usuario de la base de datos: " db_user
read -sp "Introduce la contraseña de la base de datos: " db_password
echo

# Actualizar el sistema
echo "Actualizando el sistema..."
apt update && apt upgrade -y

# Agregar repositorio para PHP 7.4
echo "Agregando repositorio para PHP 7.4..."
add-apt-repository ppa:ondrej/php -y
apt update

# Instalar Apache, PHP 7.4 y las extensiones necesarias
echo "Instalando Apache, PHP 7.4 y extensiones..."
apt install -y apache2 mysql-server php7.4 php7.4-cli php7.4-fpm php7.4-mysql php7.4-xml \
php7.4-xmlrpc php7.4-soap php7.4-intl php7.4-zip php7.4-mbstring php7.4-curl php7.4-gd unzip

# Configurar Apache para usar PHP 7.4
echo "Configurando Apache para usar PHP 7.4..."
a2dismod php8.3 > /dev/null 2>&1 || true
a2enmod php7.4
systemctl restart apache2

# Descargar Moodle
echo "Descargando Moodle..."
wget -q https://download.moodle.org/stable40/moodle-latest-40.tgz -O /tmp/moodle.tgz

# Extraer Moodle
echo "Instalando Moodle en /var/www/html/moodle..."
tar -xzf /tmp/moodle.tgz -C /var/www/html
mkdir /var/www/html/moodledata
chown -R www-data:www-data /var/www/html/moodle /var/www/html/moodledata
chmod -R 755 /var/www/html/moodle /var/www/html/moodledata

# Configurar base de datos para Moodle
echo "Configurando la base de datos..."
mysql -u root <<EOF
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON moodle.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Ajustar configuración de PHP
echo "Ajustando configuración de PHP..."
sed -i "s/^max_execution_time = .*/max_execution_time = 300/" /etc/php/7.4/apache2/php.ini
sed -i "s/^memory_limit = .*/memory_limit = 128M/" /etc/php/7.4/apache2/php.ini
sed -i "s/^post_max_size = .*/post_max_size = 64M/" /etc/php/7.4/apache2/php.ini
sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 64M/" /etc/php/7.4/apache2/php.ini
systemctl restart apache2

# Información final
clear
echo "=== Instalación completa ==="
echo "Moodle ha sido instalado correctamente."
echo "Información de la base de datos:"
echo "Usuario de la base de datos: $db_user"
echo "Contraseña de la base de datos: $db_password"
echo "URL para continuar con la instalación desde el navegador:"
echo "http://<TU_IP>/moodle"

exit 0
# 33