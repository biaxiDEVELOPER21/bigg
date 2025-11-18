#!/bin/bash
# Auto Install WordPress on Debian 12 (Apache2 + PHP-FPM + MariaDB)

set -e

echo "=== Updating system ==="
apt update && apt upgrade -y

echo "=== Installing dependencies ==="
apt install -y unzip curl wget lsb-release ca-certificates apt-transport-https

echo "=== Installing Apache2 ==="
apt install -y apache2
systemctl enable apache2
systemctl start apache2

echo "=== Installing MariaDB ==="
apt install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb

echo "=== Configuring MariaDB root user ==="
mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'rootpass123';
FLUSH PRIVILEGES;
EOF

echo "=== Creating WordPress Database ==="
mysql -u root -prootpass123 <<EOF
CREATE DATABASE wp_db;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'passwordku123';
GRANT ALL PRIVILEGES ON wp_db.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "=== Installing PHP + Extensions ==="
apt install -y php php-fpm php-mysql php-xml php-gd php-mbstring php-curl php-zip php-intl php-cli php-common

echo "=== Enabling PHP-FPM in Apache ==="
a2enmod proxy_fcgi setenvif
a2enconf php8.2-fpm
a2enmod rewrite

systemctl restart php8.2-fpm
systemctl restart apache2

echo "=== Downloading WordPress ==="
cd /var/www
wget -q https://wordpress.org/latest.zip
unzip -q latest.zip
rm latest.zip
mv wordpress mysite

echo "=== Setting permissions for WordPress ==="
chown -R www-data:www-data /var/www/mysite
chmod -R 755 /var/www/mysite

echo "=== Configuring WordPress wp-config.php ==="
cp /var/www/mysite/wp-config-sample.php /var/www/mysite/wp-config.php

sed -i "s/database_name_here/wp_db/" /var/www/mysite/wp-config.php
sed -i "s/username_here/wp_user/" /var/www/mysite/wp-config.php
sed -i "s/password_here/passwordku123/" /var/www/mysite/wp-config.php

echo "=== Creating Apache Virtual Host ==="
cat > /etc/apache2/sites-available/mysite.conf <<EOF
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/mysite

    <Directory /var/www/mysite>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/mysite_error.log
    CustomLog \${APACHE_LOG_DIR}/mysite_access.log combined
</VirtualHost>
EOF

echo "=== Enabling site ==="
a2ensite mysite.conf
a2dissite 000-default.conf
systemctl reload apache2

echo "=== INSTALLATION COMPLETE ==="
echo "========================================="
echo "WordPress installed successfully!"
echo "Open your browser:"
echo "  http://YOUR_SERVER_IP/"
echo "========================================="
