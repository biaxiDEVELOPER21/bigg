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


echo "=============================================="
echo "INSTALL SELESAI (MODE LOCALHOST)"
echo "Akses Roundcube: http://localhost/roundcube"
echo "Login akun:"
echo "   user1@localhost  (password: password123)"
echo "   user2@localhost  (password: password123)"
echo "=============================================="
