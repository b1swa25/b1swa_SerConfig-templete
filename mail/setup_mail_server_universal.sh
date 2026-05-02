#!/bin/bash

# ==============================================================================
# Script: setup_mail_server_universal.sh
# Description: Mail Server Setup (Postfix, Dovecot, Roundcube, MariaDB)
# Supported OS: Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux
# Copyright: © b1swa
# Contact: sandipbiswa10@gmail.com
# ==============================================================================

# Exit on error
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check for whiptail
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail is required. Please install it first (e.g., apt install whiptail / dnf install newt)."
    exit 1
fi

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo."
    exit 1
fi

# 1. OS Detection Engine
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_LIKE=${ID_LIKE:-$ID}
else
    echo "Cannot detect OS. /etc/os-release missing."
    exit 1
fi

OS_FAMILY=""
if [[ "$OS" == *"ubuntu"* || "$OS" == *"debian"* || "$OS_LIKE" == *"ubuntu"* || "$OS_LIKE" == *"debian"* ]]; then
    OS_FAMILY="debian"
    PKG_MGR="apt-get"
    WEB_SRV="apache2"
    DB_SRV="mariadb-server"
    WEB_USER="www-data"
    WEB_CONF_DIR="/etc/apache2/sites-available"
    PHP_PKGS="php libapache2-mod-php php-mysql php-mbstring php-intl php-xml php-curl"
elif [[ "$OS" == *"centos"* || "$OS" == *"rhel"* || "$OS" == *"fedora"* || "$OS_LIKE" == *"rhel"* || "$OS_LIKE" == *"fedora"* || "$OS" == *"almalinux"* || "$OS" == *"rocky"* ]]; then
    OS_FAMILY="rhel"
    PKG_MGR="dnf"
    if ! command -v dnf &> /dev/null; then PKG_MGR="yum"; fi
    WEB_SRV="httpd"
    DB_SRV="mariadb-server"
    WEB_USER="apache"
    WEB_CONF_DIR="/etc/httpd/conf.d"
    PHP_PKGS="php php-mysqlnd php-mbstring php-intl php-xml php-json curl"
elif [[ "$OS" == *"arch"* || "$OS_LIKE" == *"arch"* ]]; then
    OS_FAMILY="arch"
    PKG_MGR="pacman"
    WEB_SRV="apache"
    DB_SRV="mariadb"
    WEB_USER="http"
    WEB_CONF_DIR="/etc/httpd/conf/extra"
    PHP_PKGS="php php-apache php-sqlite sqlite" # Simplification for Arch
else
    echo -e "${RED}Unsupported OS family: $OS / $OS_LIKE${NC}"
    exit 1
fi

# 2. Branding
show_branding() {
    local HOSTNAME=$(hostname)
    local HOST_IP=$(hostname -I | awk '{print $1}')
    whiptail --title "Universal Mail Server Setup" --msgbox "Welcome to the Universal Mail Server Setup Tool\n\n[ System Information ]\nHostname: $HOSTNAME\nHost IP: $HOST_IP\nDetected OS: $OS ($OS_FAMILY)\n\nEngine: Postfix, Dovecot, Roundcube, MariaDB\nCopyright © b1swa\nContact: sandipbiswa10@gmail.com" 18 65
}
show_branding

# 3. Get Inputs
DOMAIN=$(whiptail --title "Domain Name" --inputbox "Enter the domain name for the Mail Server:" 10 60 "b1swa.local" 3>&1 1>&2 2>&3)
SERVER_IP=$(whiptail --title "Server IP Address" --inputbox "Enter the IP address of this Mail Server:" 10 60 "127.0.0.1" 3>&1 1>&2 2>&3)

DEFAULT_IFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
[ -z "$DEFAULT_IFACE" ] && DEFAULT_IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | head -n1)
INTERFACE=$(whiptail --title "Network Interface" --inputbox "Enter the network interface to bind to:" 10 60 "$DEFAULT_IFACE" 3>&1 1>&2 2>&3)

ORG_NAME=$(whiptail --title "Organization Name" --inputbox "Enter the Organization Name:" 10 60 "b1swa Private Limited" 3>&1 1>&2 2>&3)
PROVIDER_LINK=$(whiptail --title "Provider Link" --inputbox "Enter the URL for the Webmail provider link:" 10 60 "http://$DOMAIN/" 3>&1 1>&2 2>&3)
ADMIN_EMAIL=$(whiptail --title "Admin Email" --inputbox "Enter the Postmaster/Admin email address:" 10 60 "admin@$DOMAIN" 3>&1 1>&2 2>&3)

NETWORKS=$(whiptail --title "Allowed Networks" --inputbox "Enter the allowed networks (mynetworks):" 10 60 "127.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 10.0.0.0/8" 3>&1 1>&2 2>&3)

TEST_USERS=$(whiptail --title "Test Users" --inputbox "Enter the test usernames to create (comma separated):" 10 60 "b1swa,cyber" 3>&1 1>&2 2>&3)
USER_PASS=$(whiptail --title "Test User Password" --passwordbox "Enter the default password for the test users:" 10 60 "password123" 3>&1 1>&2 2>&3)

# --- Execution with Progress Gauge ---

{
    echo 5; sleep 1
    echo "XXX"
    echo "📦 Phase 1: Installing Packages via $PKG_MGR..."
    echo "XXX"
    
    if [ "$OS_FAMILY" == "debian" ]; then
        export DEBIAN_FRONTEND=noninteractive
        echo "postfix postfix/mailname string $DOMAIN" | debconf-set-selections
        echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
        $PKG_MGR update -y > /dev/null
        $PKG_MGR install -y postfix dovecot-core dovecot-imapd dovecot-pop3d $WEB_SRV $DB_SRV $PHP_PKGS unzip wget > /dev/null
    elif [ "$OS_FAMILY" == "rhel" ]; then
        $PKG_MGR install -y epel-release > /dev/null || true
        $PKG_MGR install -y postfix dovecot $WEB_SRV $DB_SRV $PHP_PKGS unzip wget > /dev/null
    elif [ "$OS_FAMILY" == "arch" ]; then
        $PKG_MGR -Sy --noconfirm postfix dovecot $WEB_SRV $DB_SRV $PHP_PKGS unzip wget > /dev/null
    fi
    
    echo 25; sleep 1
    echo "XXX"
    echo "🔧 Phase 2: Configuring Postfix & Dovecot..."
    echo "XXX"
    
    cat <<EOF > /etc/postfix/main.cf
# ==============================================================================
# Postfix Configuration
# Generated by setup_mail_server_universal.sh
# Copyright © b1swa
# ==============================================================================
smtpd_banner = \$myhostname ESMTP \$mail_name ($OS)
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 3.6

myhostname = mail.$DOMAIN
mydomain = $DOMAIN
myorigin = \$mydomain
inet_interfaces = all
inet_protocols = all
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
mynetworks = $NETWORKS
home_mailbox = Maildir/
EOF

    if ! grep -q "postmaster:" /etc/aliases; then
        echo "postmaster: $ADMIN_EMAIL" >> /etc/aliases
        newaliases || true
    else
        sed -i "s/^postmaster:.*/postmaster: $ADMIN_EMAIL/g" /etc/aliases
        newaliases || true
    fi

    if [ -f /etc/dovecot/dovecot.conf ]; then
        sed -i 's/#protocols = imap pop3 lmtp submission/protocols = imap pop3 lmtp/g' /etc/dovecot/dovecot.conf
    fi
    if [ -f /etc/dovecot/conf.d/10-mail.conf ]; then
        sed -i 's|#mail_location =|mail_location = maildir:~/Maildir|g' /etc/dovecot/conf.d/10-mail.conf
    fi
    if [ -f /etc/dovecot/conf.d/10-auth.conf ]; then
        sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g' /etc/dovecot/conf.d/10-auth.conf
        sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/g' /etc/dovecot/conf.d/10-auth.conf
    fi

    echo 40; sleep 1
    echo "XXX"
    echo "🔥 Phase 3: Configuring Firewall..."
    echo "XXX"
    
    if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
        ufw allow in on "$INTERFACE" to any port 25 proto tcp > /dev/null
        ufw allow in on "$INTERFACE" to any port 143 proto tcp > /dev/null
        ufw allow in on "$INTERFACE" to any port 110 proto tcp > /dev/null
        ufw allow in on "$INTERFACE" to any port 80 proto tcp > /dev/null
    elif command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --zone=public --add-port=25/tcp > /dev/null
        firewall-cmd --permanent --zone=public --add-port=143/tcp > /dev/null
        firewall-cmd --permanent --zone=public --add-port=110/tcp > /dev/null
        firewall-cmd --permanent --zone=public --add-port=80/tcp > /dev/null
        firewall-cmd --reload > /dev/null
    fi

    echo 50; sleep 1
    echo "XXX"
    echo "🗄️ Phase 4: Setting up MariaDB Database..."
    echo "XXX"
    
    # Arch needs mariadb-install-db first
    if [ "$OS_FAMILY" == "arch" ] && [ ! -d "/var/lib/mysql/mysql" ]; then
        mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql > /dev/null 2>&1
    fi
    
    if systemctl list-unit-files | grep -q mariadb; then
        systemctl restart mariadb
        systemctl enable mariadb
    elif systemctl list-unit-files | grep -q mysqld; then
        systemctl restart mysqld
        systemctl enable mysqld
    fi
    
    sleep 2 # wait for db to start
    
    # Run SQL commands securely
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS roundcubemail /*\!40101 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;" || true
    mysql -u root -e "CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY 'roundcubepass';" || true
    mysql -u root -e "ALTER USER 'roundcube'@'localhost' IDENTIFIED BY 'roundcubepass';" || true
    mysql -u root -e "GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';" || true
    mysql -u root -e "FLUSH PRIVILEGES;" || true

    echo 65; sleep 1
    echo "XXX"
    echo "📝 Phase 5: Installing Roundcube Webmail..."
    echo "XXX"
    
    mkdir -p /usr/share/roundcube
    cd /usr/share/roundcube
    wget -qO roundcube.tar.gz https://github.com/roundcube/roundcubemail/releases/download/1.6.15/roundcubemail-1.6.15-complete.tar.gz
    tar -xzf roundcube.tar.gz --strip-components=1
    rm roundcube.tar.gz

    chown -R $WEB_USER:$WEB_USER /usr/share/roundcube/temp
    chown -R $WEB_USER:$WEB_USER /usr/share/roundcube/logs

    # Import initial database
    mysql -u root roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql || true

    # Generate Roundcube Config
    cat <<EOF > /usr/share/roundcube/config/config.inc.php
<?php
\$config = [];
\$config['db_dsnw'] = 'mysql://roundcube:roundcubepass@localhost/roundcubemail';
\$config['imap_host'] = 'localhost:143';
\$config['smtp_host'] = 'localhost:25';
\$config['smtp_user'] = '';
\$config['smtp_pass'] = '';
\$config['support_url'] = '$PROVIDER_LINK';
\$config['product_name'] = '$ORG_NAME Webmail';
\$config['des_key'] = '$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)';
\$config['plugins'] = [];
\$config['language'] = 'en_US';
EOF

    echo 80; sleep 1
    echo "XXX"
    echo "🚀 Phase 6: Configuring Apache and Starting Services..."
    echo "XXX"

    mkdir -p "$WEB_CONF_DIR"
    CONF_FILE="$WEB_CONF_DIR/roundcube.conf"
    
    cat <<EOF > "$CONF_FILE"
Alias /webmail /usr/share/roundcube
<Directory /usr/share/roundcube>
    Options -Indexes
    AllowOverride All
    Require all granted
</Directory>
EOF

    if [ "$OS_FAMILY" == "debian" ]; then
        a2ensite roundcube > /dev/null 2>&1 || true
    elif [ "$OS_FAMILY" == "rhel" ] || [ "$OS_FAMILY" == "arch" ]; then
        # Ensure conf.d is included in httpd.conf
        if ! grep -q "IncludeOptional conf.d/\*.conf" /etc/httpd/conf/httpd.conf 2>/dev/null; then
            echo "IncludeOptional conf.d/*.conf" >> /etc/httpd/conf/httpd.conf || true
        fi
    fi

    systemctl restart $WEB_SRV || true
    systemctl enable $WEB_SRV || true
    systemctl restart postfix || true
    systemctl enable postfix || true
    systemctl restart dovecot || true
    systemctl enable dovecot || true
    
    echo 90; sleep 1
    echo "XXX"
    echo "👤 Phase 7: Creating Test Users..."
    echo "XXX"
    
    IFS=',' read -ra ADDR <<< "$TEST_USERS"
    for user in "\${ADDR[@]}"; do
        user=\$(echo "\$user" | xargs)
        if [ -n "\$user" ] && ! id "\$user" &>/dev/null; then
            useradd -m -s /bin/bash "\$user" || true
            echo "\$user:\$USER_PASS" | chpasswd || true
        fi
    done

    echo 100; sleep 1
} | whiptail --title "Installation Progress" --gauge "Preparing to install..." 10 60 0

# Final Message
whiptail --title "Success!" --msgbox "Mail Server is now LIVE with Roundcube!\n\nDetected OS: $OS ($OS_FAMILY)\nDomain: $DOMAIN\nServer IP: $SERVER_IP\nWebmail URL: http://$SERVER_IP/webmail\n\n[ Status ]\n- Engine: Postfix, Dovecot, Roundcube, MariaDB\n- Test Users: $TEST_USERS\n- Password: $USER_PASS\n\nCopyright © b1swa\nContact: sandipbiswa10@gmail.com" 24 70

echo -e "${GREEN}✅ Done! Mail server is configured for $DOMAIN.${NC}"
echo -e "${GREEN}Check status with: systemctl status postfix dovecot $WEB_SRV mariadb${NC}"
echo -e "${GREEN}Access webmail at: http://$SERVER_IP/webmail${NC}"
