#!/bin/bash
# Mail Server Setup Script – Debian 12
# Postfix + Dovecot + Roundcube (Auto Config)

if [ "$EUID" -ne 0 ]; then
  echo "Harap jalankan sebagai root"
  exit 1
fi

echo "Updating system..."
apt update -y
apt upgrade -y

echo "Installing required packages..."
DEBIAN_FRONTEND=noninteractive apt install -y postfix dovecot-imapd dovecot-pop3d mailutils mariadb-server apache2 php php-cli php-mysql php-zip php-xml php-mbstring php-intl unzip wget

# ============================
#  KONFIGURASI POSTFIX
# ============================
echo "Configuring Postfix..."
postconf -e "myhostname = mail.namadomain.com"
postconf -e "myorigin = /etc/mailname"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
postconf -e "relayhost ="
postconf -e "mynetworks = 127.0.0.0/8"
postconf -e "mailbox_size_limit = 0"
postconf -e "recipient_delimiter = +"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"

systemctl restart postfix
systemctl enable postfix

# ============================
#  KONFIGURASI DOVECOT
# ============================
echo "Configuring Dovecot..."
cat > /etc/dovecot/dovecot.conf <<EOF
disable_plaintext_auth = no
mail_location = mbox:~/mail:INBOX=/var/mail/%u
EOF

systemctl restart dovecot
systemctl enable dovecot

# ============================
#   ADD USER EMAIL
# ============================
read -p "Masukkan username untuk email baru: " mailuser
adduser $mailuser

echo "User $mailuser ditambahkan."

# ============================
#   DATABASE ROUNDCUBE
# ============================
echo "Creating Roundcube database..."

mysql -e "CREATE DATABASE roundcube;"
mysql -e "CREATE USER 'roundcube'@'localhost' IDENTIFIED BY 'strongpassword123';"
mysql -e "GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# ============================
#  INSTALL ROUNDCUBE
# ============================
echo "Installing Roundcube..."
apt install -y roundcube

# ============================
#   BUAT FILE CONFIG ROUNDCUBE
# ============================
echo "Creating Roundcube config file..."

cat > /etc/roundcube/config.inc.php <<'EOF'
<?php
$config['db_dsnw'] = 'mysql://roundcube:strongpassword123@localhost/roundcube';

$config['default_host'] = 'localhost';
$config['default_port'] = 143;

$config['smtp_server'] = 'localhost';
$config['smtp_port'] = 587;

$config['support_url'] = '';
$config['des_key'] = 'rcmail-1234567890abcdef';

$config['plugins'] = array(
  'archive',
  'zipdownload',
  'managesieve',
);

$config['language'] = 'en_US';
$config['timezone'] = 'Asia/Jakarta';
EOF

# set permission
chown -R www-data:www-data /etc/roundcube
chmod 640 /etc/roundcube/config.inc.php

systemctl restart apache2

echo "Roundcube configuration complete!"
echo "Akses Webmail: http://IP-SERVER/roundcube"

# ============================
#   TEST KIRIM EMAIL
# ============================
echo "Mengirim email test ke $mailuser..."
echo "Test mail server" | mail -s "Mail Server Test" $mailuser@localhost

echo "===== INSTALL COMPLETE ====="
echo "Login Roundcube:"
echo "Username  : $mailuser"
echo "Password  : password user Linux Anda"
