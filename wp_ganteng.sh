#!/bin/bash
# Auto Install WordPress on Debian 12 (Apache2 + PHP-FPM + MariaDB)

set -e

echo "=== Updating system ==="
apt update && apt upgrade -y

echo "=== Installing dependencies ==="
apt install -y unzip curl wget

echo "=== Installing Apache2 ==="
apt install -y apache2
systemctl enable apache2
systemctl start apache2

echo "=== Installing MariaDB ==="
apt install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb

echo "=== Securing MariaDB ==="
mysql -e "UPDATE mysql.user SET Password=PASSWORD('rootpass123') WHERE User='root'; FLUSH PRIVILEGES;"
mysql_secure_installation <<EOF
n
y
y
y
y
EOF

echo "=== Creating WordPress Database ==="
mysql -u root -prootpass123 <<EOF
CREATE DATABASE wp_db;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'passwordku123';
GRANT ALL PRIVILEGES ON wp_db.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "=== Installing PHP 8.2 + extensions ==="
apt install -y php php-fpm php-mysql php-xml php-gd php-mbstring php-curl php-zip php-intl

echo "=== Enabling Apache PHP-FPM ==="
a2enmod proxy_fcgi setenvif
a2enconf php8.2-fpm

echo "=== Downloading WordPress ==="
cd /var/www
wget https://wordpress.org/latest.zip
unzip latest.zip
mv wordpress mysite
chown -R www-data:www-data /var/www/mysite
chmod -R 755 /var/www/mysite

echo "=== Configuring WordPress ==="
cp /var/www/mysite/wp-config-sample.php /var/www/mysite/wp-config.php
sed -i "s/database_name_here/wp_db/" /var/www/mysite/wp-config.php
sed -i "s/username_here/wp_user/" /var/www/mysite/wp-config.php
sed -i "s/password_here/passwordku123/" /var/www/mysite/wp-config.php

echo "=== Creating Apache Virtual Host ==="
cat > /etc/apache2/sites-available/mysite.conf << 'EOF'
<VirtualHost *:80>
    ServerName _
    DocumentRoot /var/www/mysite
    <Directory /var/www/mysite>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

a2ensite mysite.conf
a2enmod rewrite
systemctl restart apache2

echo "=== Installation Complete ==="
echo "Open your browser and go to: http://YOUR_SERVER_IP/"
