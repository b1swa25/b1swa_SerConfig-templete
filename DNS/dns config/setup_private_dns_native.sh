#!/bin/bash

# ==============================================================================
# Script: setup_private_dns_native.sh
# Description: Native BIND9 DNS Setup with Progress Tracking
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
    echo "Error: whiptail is required."
    exit 1
fi

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo."
    exit 1
fi

# 1. Branding
show_branding() {
    local HOSTNAME=$(hostname)
    local HOST_IP=$(hostname -I | awk '{print $1}')
    whiptail --title "Native Private DNS (BIND9)" --msgbox "Welcome to the Native Private DNS Setup Tool\n\n[ System Information ]\nHostname: $HOSTNAME\nHost IP: $HOST_IP\n\nEngine: BIND9 (Native)\nCopyright © b1swa\nContact: sandipbiswa10@gmail.com" 16 65
}
show_branding

# 2. Get Inputs
DOMAIN=$(whiptail --title "Domain" --inputbox "Enter the private domain name:" 10 60 "b1swa.local" 3>&1 1>&2 2>&3)
TARGET_IP=$(whiptail --title "Target IP" --inputbox "Enter the IP for $DOMAIN:" 10 60 "$(hostname -I | awk '{print $1}')" 3>&1 1>&2 2>&3)
UPSTREAM=$(whiptail --title "Upstream DNS" --inputbox "Enter upstream DNS (for internet):" 10 60 "8.8.8.8" 3>&1 1>&2 2>&3)

# Generate Dynamic Serial (YYYYMMDDNN)
SERIAL=$(date +%Y%m%d)01

# --- Execution with Progress Gauge ---

{
    echo 10; sleep 1
    echo "XXX"
    echo "📦 Phase 1: Installing BIND9..."
    echo "XXX"
    apt-get update -y > /dev/null
    apt-get install -y bind9 bind9utils bind9-doc > /dev/null
    
    echo 30; sleep 1
    echo "XXX"
    echo "🔧 Phase 2: Resolving Port 53 conflicts..."
    echo "XXX"
    if ! grep -q "DNSStubListener=no" /etc/systemd/resolved.conf; then
        echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
        systemctl restart systemd-resolved
    fi
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf || true

    echo 50; sleep 1
    echo "XXX"
    echo "📝 Phase 3: Configuring BIND9 Options..."
    echo "XXX"
    cat <<EOF > /etc/bind/named.conf.options
options {
        directory "/var/cache/bind";
        forwarders { $UPSTREAM; };
        dnssec-validation auto;
        listen-on { any; };
        allow-query { any; };
};
EOF

    echo 70; sleep 1
    echo "XXX"
    echo "📝 Phase 4: Creating Zone Files..."
    echo "XXX"
    IFS='.' read -r o1 o2 o3 o4 <<< "$TARGET_IP"
    REVERSE_ZONE="$o3.$o2.$o1.in-addr.arpa"
    
    cat <<EOF > /etc/bind/named.conf.local
zone "$DOMAIN" { type master; file "/etc/bind/zones/db.$DOMAIN"; };
zone "$REVERSE_ZONE" { type master; file "/etc/bind/zones/db.reverse"; };
EOF

    mkdir -p /etc/bind/zones
    cat <<EOF > /etc/bind/zones/db.$DOMAIN
\$TTL 1D
@ IN SOA ns1.$DOMAIN. admin.$DOMAIN. (
                  $SERIAL ; serial
                  4H         ; refresh
                  30M        ; retry
                  2W         ; expire
                  1H )       ; minimum
@ IN NS ns1.$DOMAIN.
ns1 IN A $TARGET_IP
@ IN A $TARGET_IP
www IN A $TARGET_IP
EOF

    cat <<EOF > /etc/bind/zones/db.reverse
\$TTL 1D
@ IN SOA ns1.$DOMAIN. admin.$DOMAIN. (
                  $SERIAL ; serial
                  4H         ; refresh
                  30M        ; retry
                  2W         ; expire
                  1H )       ; minimum
@ IN NS ns1.$DOMAIN.
$o4 IN PTR $DOMAIN.
EOF

    echo 90; sleep 1
    echo "XXX"
    echo "🔥 Phase 5: Configuring Firewall (UFW)..."
    echo "XXX"
    if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
        ufw allow 53/udp > /dev/null
        ufw allow 53/tcp > /dev/null
    fi

    echo 100; sleep 1
    echo "XXX"
    echo "🚀 Phase 6: Starting DNS Service..."
    echo "XXX"
    named-checkconf
    systemctl restart named
    systemctl enable named

} | whiptail --title "Installation Progress" --gauge "Preparing to install..." 10 60 0

# Final Message
whiptail --title "Success!" --msgbox "BIND9 Private DNS is now LIVE!\n\nDomain: $DOMAIN\nIP: $TARGET_IP\n\n[ Status ]\n- Engine: BIND9 (Native)\n- Conflict: systemd-resolved stub disabled\n- Firewall: Port 53 (UDP/TCP) allowed\n\nCopyright © b1swa\nContact: sandipbiswa10@gmail.com" 18 70

echo -e "${GREEN}✅ Done! Test with: dig @localhost $DOMAIN${NC}"
