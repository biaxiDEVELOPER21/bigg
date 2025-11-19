#!/bin/bash
set -e

### === KONFIGURASI LOCAL ONLY === ###
DOMAIN="localhost"
DBPASS="PasswordSQLRoundcube"
### ================================= ###

echo "[1/10] Update paket..."
apt update -y && apt upgrade -y

echo "[2/10] Install Postfix + Dovecot + MariaDB + PHP..."
DEBIAN_FRONTEND=noninteractive apt install -y postfix dovecot-core dovecot-imapd mariadb-server \
php php-mysql php-xml php-gd php-intl php-mbstring php-zip php-curl \
apache2 unzip wget composer

echo "[3/10] Konfigurasi Postfix..."
postconf -e "myhostname=localhost"
postconf -e "mydomain=$DOMAIN"
postconf -e "myorigin=\$mydomain"
postconf -e "inet_interfaces=all"
postconf -e "inet_protocols=ipv4"
postconf -e "mydestination=\$myhostname, localhost.\$mydomain, localhost"
postconf -e "home_mailbox=Maildir/"
postconf -e "smtpd_banner=\$myhostname ESMTP"
systemctl restart postfix

echo "[4/10] Konfigurasi Dovecot..."
cat > /etc/dovecot/dovecot.conf <<EOF
protocols = imap
mail_location = maildir:~/Maildir
disable_plaintext_auth = no
EOF

cat > /etc/dovecot/conf.d/10-auth.conf <<EOF
disable_plaintext_auth = no
auth_mechanisms = plain login
!include auth-system.conf.ext
EOF

cat > /etc/dovecot/conf.d/10-mail.conf <<EOF
mail_location = maildir:~/Maildir
EOF

systemctl restart dovecot

echo "[5/10] Buat user email..."
useradd -m user1 || true
echo "user1:password123" | chpasswd

useradd -m user2 || true
echo "user2:password123" | chpasswd

echo "[6/10] Buat database roundcube..."
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS roundcube;
CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY '$DBPASS';
GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[7/10] Download Roundcube..."
cd /var/www/html
wget https://github.com/roundcube/roundcubemail/releases/download/1.6.7/roundcubemail-1.6.7-complete.tar.gz
tar -xvf roundcubemail-1.6.7-complete.tar.gz
mv roundcubemail-1.6.7 roundcube
rm roundcubemail-1.6.7-complete.tar.gz
cd roundcube

echo "[8/10] Install Roundcube..."
composer install --no-dev
cp config/config.inc.php.sample config/config.inc.php

sed -i "s|\$config\['db_dsnw'\].*|\$config['db_dsnw'] = 'mysql://roundcube:$DBPASS@localhost/roundcube';|" config/config.inc.php
sed -i "s|// \$config\['default_host'\].*|\$config['default_host'] = 'localhost';|" config/config.inc.php
sed -i "s|// \$config\['smtp_server'\].*|\$config['smtp_server'] = 'localhost';|" config/config.inc.php

echo "[9/10] Import database schema..."
mysql -u root roundcube < SQL/mysql.initial.sql

echo "[10/10] Set permission & restart Apache..."
chown -R www-data:www-data /var/www/html/roundcube
systemctl restart apache2 postfix dovecot

echo "=============================================="
echo "INSTALL SELESAI (MODE LOCALHOST)"
echo "Akses Roundcube: http://localhost/roundcube"
echo "Login akun:"
echo "   user1@localhost  (password: password123)"
echo "   user2@localhost  (password: password123)"
echo "=============================================="
