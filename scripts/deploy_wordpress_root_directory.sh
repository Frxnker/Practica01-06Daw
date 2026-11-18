#!/bin/bash
set -ex

source .env

# 1. Descargar WordPress
rm -rf /tmp/latest.tar.gz /tmp/wordpress
wget https://wordpress.org/latest.tar.gz -P /tmp
tar -xzvf /tmp/latest.tar.gz -C /tmp

# 2. Vaciar el directorio web y mover WordPress
rm -rf /var/www/html/*
mv -f /tmp/wordpress/* /var/www/html

# 3. Base de datos y usuario
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

# 4. Crear wp-config.php con los datos de la base de datos
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wp-config.php

# 5. Claves de seguridad
sed -i "/AUTH_KEY/d" /var/www/html/wp-config.php
sed -i "/SECURE_AUTH_KEY/d" /var/www/html/wp-config.php
sed -i "/LOGGED_IN_KEY/d" /var/www/html/wp-config.php
sed -i "/NONCE_KEY/d" /var/www/html/wp-config.php
sed -i "/AUTH_SALT/d" /var/www/html/wp-config.php
sed -i "/SECURE_AUTH_SALT/d" /var/www/html/wp-config.php
sed -i "/LOGGED_IN_SALT/d" /var/www/html/wp-config.php
sed -i "/NONCE_SALT/d" /var/www/html/wp-config.php
SECURITY_KEYS=$(curl https://api.wordpress.org/secret-key/1.1/salt/)
SECURITY_KEYS=$(echo $SECURITY_KEYS | tr / _)
sed -i "/@-/a $SECURITY_KEYS" /var/www/html/wp-config.php

# 6. Enlaces permanentes
cp ../htaccess/.htaccess /var/www/html/
a2enmod rewrite
systemctl restart apache2

# 7. Propietario
chown -R www-data:www-data /var/www/html/