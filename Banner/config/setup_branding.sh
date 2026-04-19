#!/bin/bash

# ==============================================================================
# Script: setup_branding.sh
# Description: Minimalist Professional Terminal Branding Suite
# Copyright © B1SWA
# ==============================================================================

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo."
    exit 1
fi

# 1. Dependency Auto-Installation
echo "Checking for dependencies..."
for cmd in whiptail paste sed awk grep free df; do
    if ! command -v $cmd &> /dev/null; then
        echo "[INFO] $cmd not found. Attempting to install..."
        if command -v apt-get &> /dev/null; then
            apt-get update -qq && apt-get install -y -qq $cmd
        elif command -v dnf &> /dev/null; then
            dnf install -y -q $cmd
        elif command -v yum &> /dev/null; then
            yum install -y -q $cmd
        elif command -v pacman &> /dev/null; then
            pacman -Sy --noconfirm --noprogressbar $cmd
        fi
    fi
done

# 2. Get User Input
ORG_NAME=$(whiptail --title "Minimalist Branding" --inputbox "Enter Organization Name:" 10 60 "B1SWA" 3>&1 1>&2 2>&3)
ADMIN_NAME=$(whiptail --title "Minimalist Branding" --inputbox "Enter Administrator Name:" 10 60 "Admin" 3>&1 1>&2 2>&3)
ADMIN_EMAIL=$(whiptail --title "Minimalist Branding" --inputbox "Enter Administrator Email:" 10 60 "sandipbiswa10@gmail.com" 3>&1 1>&2 2>&3)

# 2.1 Timezone Setup
CURRENT_TZ=$(cat /etc/timezone 2>/dev/null || echo "UTC")
SELECTED_TZ=$(whiptail --title "Timezone Configuration" --inputbox "Enter your Timezone (e.g., Asia/Thimphu):" 10 60 "Asia/Thimphu" 3>&1 1>&2 2>&3)
if [ -n "$SELECTED_TZ" ]; then
    echo "🕒 Setting system timezone to $SELECTED_TZ..."
    timedatectl set-timezone "$SELECTED_TZ" 2>/dev/null
fi

# 3. System Info Gathering
PRETTY_NAME=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | awk -F'"' '{print $2}' | head -n1)
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' | cut -c1-30)
TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
IP_ADDR=$(hostname -I | awk '{print $1}')


# 5. Generate Pre-login Banner File
BRANDING_DIR="/etc/branding"
mkdir -p "$BRANDING_DIR"
{
    BLUE='\033[0;34m'
    NC='\033[0m'
    echo -e "${BLUE}##############################################################################${NC}"
    echo -e "${BLUE}##${NC}                                                                          ${BLUE}##${NC}"
    printf "${BLUE}##${NC}%*s%s%*s${BLUE}##${NC}\n" $(((74-39-${#ORG_NAME})/2)) "" "WELCOME TO THE $ORG_NAME SECURE ACCESS TERMINAL" $(((74-39-${#ORG_NAME}+1)/2)) ""
    echo -e "${BLUE}##${NC}                                                                          ${BLUE}##${NC}"
    echo -e "${BLUE}##############################################################################${NC}"
    echo ""
    echo ""
    echo "  [>>] SYSTEM PROFILE"
    echo "  OS:      $PRETTY_NAME"
    echo "  Host:    \n"
    echo "  Kernel:  \r (\m)"
    echo "  CPU:     $CPU_MODEL"
    echo "  RAM:     $TOTAL_RAM"
    echo "  IP:      $IP_ADDR"
    echo "  Time:    \t"
    echo ""
    echo "  [!!] SECURITY WARNING"
    echo "  Unauthorized access is strictly monitored and prosecuted."
    echo ""
    echo -e "${BLUE}##############################################################################${NC}"
    echo "  Copyright (c) $ADMIN_NAME | $ADMIN_EMAIL"
    echo -e "${BLUE}##############################################################################${NC}"
} > "$BRANDING_DIR/pre_login_banner"

# Initial deployment
cp "$BRANDING_DIR/pre_login_banner" /etc/issue
[ -f /etc/issue.net ] && cp "$BRANDING_DIR/pre_login_banner" /etc/issue.net

# --- Dynamic Banner Refresh (Cron - 30s Pulse) ---
echo "⏲️ Setting up 30-second Dynamic Banner Refresh..."
CRON_SCRIPT="/usr/local/bin/refresh_banner.sh"
cat <<'BANNER_EOF' > "$CRON_SCRIPT"
#!/bin/bash
# Re-gather stats
PRETTY_NAME=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | awk -F'"' '{print $2}' | head -n1)
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' | cut -c1-30)
TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
IP_ADDR=$(hostname -I | awk '{print $1}')
ORG_NAME=$(grep "WELCOME TO THE" /etc/issue | awk -F'THE ' '{print $2}' | awk -F' SECURE' '{print $1}')
ADMIN_INFO=$(grep "Copyright (c)" /etc/issue)

{
    BLUE='\033[0;34m'
    NC='\033[0m'
    echo -e "${BLUE}##############################################################################${NC}"
    echo -e "${BLUE}##${NC}                                                                          ${BLUE}##${NC}"
    printf "${BLUE}##${NC}%*s%s%*s${BLUE}##${NC}\n" $(((74-39-${#ORG_NAME})/2)) "" "WELCOME TO THE $ORG_NAME SECURE ACCESS TERMINAL" $(((74-39-${#ORG_NAME}+1)/2)) ""
    echo -e "${BLUE}##${NC}                                                                          ${BLUE}##${NC}"
    echo -e "${BLUE}##############################################################################${NC}"
    echo ""
    echo "  [>>] SYSTEM PROFILE (LIVE REFRESH)"
    echo "  OS:      $PRETTY_NAME"
    echo "  Host:    \n"
    echo "  Kernel:  \r (\m)"
    echo "  CPU:     $CPU_MODEL"
    echo "  RAM:     $TOTAL_RAM"
    echo "  IP:      $IP_ADDR"
    echo "  Time:    \t"
    echo ""
    echo "  [!!] SECURITY WARNING"
    echo "  Unauthorized access is strictly monitored and prosecuted."
    echo ""
    echo -e "${BLUE}##############################################################################${NC}"
    echo "  $ADMIN_INFO"
    echo -e "${BLUE}##############################################################################${NC}"
} > /etc/issue
BANNER_EOF

chmod +x "$CRON_SCRIPT"
# Add two cron lines for 30s interval (one direct, one with 30s offset)
(crontab -l 2>/dev/null | grep -v "$CRON_SCRIPT"; 
 echo "* * * * * $CRON_SCRIPT"; 
 echo "* * * * * sleep 30; $CRON_SCRIPT") | crontab -

# 6. Generate Dynamic MOTD Dashboard
MOTD_SCRIPT="/etc/profile.d/99-branding.sh"
cat <<EOF > "$MOTD_SCRIPT"
#!/bin/bash
if [[ \$- == *i* ]]; then
    PURPLE='\033[0;35m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    WHITE='\033[1;37m'
    BOLD_WHITE='\033[1;37m'
    BOLD_GREEN='\033[1;32m'
    BOLD_RED='\033[1;31m'
    NC='\033[0m'

    UPTIME=\$(uptime -p 2>/dev/null || uptime | cut -d',' -f1)
    LOAD=\$(cat /proc/loadavg | awk '{print \$1, \$2, \$3}')
    USERS_LOGGED=\$(who | wc -l)
    DATE_NOW=\$(date +"%A, %d %B %Y, %T")
    
    # NTP Sync Status
    SYNC_TAG="\${RED}[OUT-OF-SYNC]\${NC}"
    if timedatectl status 2>/dev/null | grep -q "System clock synchronized: yes"; then
        SYNC_TAG="\${GREEN}[SYNCED]\${NC}"
    fi

    FAILED_LOGINS=\$(journalctl _SYSTEMD_UNIT=ssh.service 2>/dev/null | grep "Failed password" | grep "\$(date +'%b %d')" | wc -l || echo "0")
    ALL_IPS=\$(hostname -I)

    MEM_PERC=\$(free | awk '/Mem:/ {printf "%.0f", \$3/\$2 * 100}')
    if [ "\$MEM_PERC" -gt 90 ]; then MEM_COLOR=\$BOLD_RED; elif [ "\$MEM_PERC" -gt 70 ]; then MEM_COLOR=\$YELLOW; else MEM_COLOR=\$GREEN; fi
    MEM_STR=\$(free -m | awk '/Mem:/ { printf "%sMB / %sMB (%d%%)", \$3, \$2, '"\$MEM_PERC"' }')

    DISK_PERC=\$(df / | awk '/\// {print \$5}' | sed 's/%//' | tail -n 1)
    if [ "\$DISK_PERC" -gt 90 ]; then DISK_COLOR=\$BOLD_RED; elif [ "\$DISK_PERC" -gt 70 ]; then DISK_COLOR=\$YELLOW; else DISK_COLOR=\$GREEN; fi
    DISK_STR=\$(df -h / | awk '/\// { printf "%s / %s (%s)", \$3, \$2, \$5 }' | tail -n 1)

    SEC_TAG="[OK]"
    [ "\$FAILED_LOGINS" -gt 0 ] && SEC_COLOR=\$BOLD_RED && SEC_TAG="[ALERT]" || SEC_COLOR=\$GREEN

    # --- HARDENING DATA ---
    PENDING_UPDATES=\$(apt-get -s dist-upgrade 2>/dev/null | grep "^Inst" | wc -l)
    UFW_STATUS=\$(ufw status 2>/dev/null | grep -i "Status" | awk '{print \$2}')
    if [[ "\$UFW_STATUS" == "active" ]]; then UFW_STATUS="\${BOLD_GREEN}ACTIVE\${NC}"; else UFW_STATUS="\${BOLD_RED}INACTIVE\${NC}"; fi
    LAST_LOGIN=\$(last -n 2 -R \$USER | head -n 2 | tail -n 1 | awk '{print \$3 " on " \$4 " " \$5 " " \$6}')

    # --- SERVICE STATUS CHECK ---
    DHCP_STATUS=\$(systemctl is-active isc-dhcp-server 2>/dev/null)
    if [[ "\$DHCP_STATUS" == "active" ]]; then DHCP_STATUS="\${BOLD_GREEN}ONLINE\${NC}"; else DHCP_STATUS="\${BOLD_RED}OFFLINE\${NC}"; fi
    DNS_STATUS=\$(systemctl is-active bind9 2>/dev/null)
    if [[ "\$DNS_STATUS" == "active" ]]; then DNS_STATUS="\${BOLD_GREEN}ONLINE\${NC}"; else DNS_STATUS="\${BOLD_RED}OFFLINE\${NC}"; fi

    echo -e "\${BLUE}##############################################################################\${NC}"
    printf "\${BLUE}##\${NC}\${BOLD_WHITE}%*s%s%*s\${NC}\${BLUE}##\${NC}\n" $(((74-38-${#ORG_NAME})/2)) "" "$ORG_NAME PRIVATE NETWORK MANAGEMENT PLATFORM" $(((74-38-${#ORG_NAME}+1)/2)) ""
    echo -e "\${BLUE}##############################################################################\${NC}"
    echo -e "  Welcome, \${CYAN}\$USER\${NC}! | \${WHITE}System Time: \$DATE_NOW \$SYNC_TAG\${NC}"
    echo ""
    echo -e "  \${PURPLE}===[ SYSTEM HEALTH ]=========================================================\${NC}"
    echo -e "  |  \${WHITE}OS:\${NC}       \$(grep PRETTY_NAME /etc/os-release | awk -F'\"' '{print \$2}' | head -n1)"
    echo -e "  |  \${WHITE}Kernel:\${NC}   \$(uname -r | cut -c1-20)     \${WHITE}Updates:\${NC} \${YELLOW}\$PENDING_UPDATES Pending\${NC}"
    echo -e "  |  \${WHITE}Uptime:\${NC}   \${WHITE}\$UPTIME\${NC}     \${WHITE}Firewall:\${NC} \$UFW_STATUS"
    echo ""
    echo -e "  \${CYAN}===[ STORAGE & MEMORY ]============\${NC}  \${YELLOW}===[ NETWORK IPS ]===============\${NC}"
    echo -e "  |  \${WHITE}Disk (/):\${NC} \${DISK_COLOR}\$DISK_STR\${NC}     |  | \${CYAN}\${ALL_IPS%% *}\${NC}"
    echo -e "  |  \${WHITE}Memory:\${NC}   \${MEM_COLOR}\$MEM_STR\${NC} |  ================================="
    echo -e "  ===================================="
    echo ""
    echo -e "  \${RED}===[ SECURITY AUDIT ]==============\${NC}  \${GREEN}===[ SERVICES ]==================\${NC}"
    echo -e "  |  \${WHITE}Failed:\${NC}    \${SEC_COLOR}\$FAILED_LOGINS \${SEC_TAG}\${NC}           |  | \${WHITE}DHCP:\${NC} \$DHCP_STATUS"
    echo -e "  |  \${WHITE}Last From:\${NC} \${WHITE}\$LAST_LOGIN\${NC} |  | \${WHITE}DNS:\${NC}  \$DNS_STATUS"
    echo -e "  ====================================  ================================="
    echo ""
    # --- THOUGHT OF THE DAY ENGINE ---
    QUOTES=(
        "Simplicity is the soul of efficiency."
        "Quality is not an act, it is a habit."
        "The only way to do great work is to love what you do."
        "Focus on being productive instead of busy."
        "Innovation distinguishes between a leader and a follower."
        "Strive not to be a success, but rather to be of value."
        "Your network is your net worth."
        "Security is not a product, but a process."
        "The best way to predict the future is to invent it."
        "Code is like humor. When you have to explain it, it’s bad."
    )
    QUOTE_IDX=\$((\$(date +%j) % \${#QUOTES[@]}))
    TODAY_QUOTE="\${QUOTES[\$QUOTE_IDX]}"

    echo -e "  \${BOLD_WHITE}SUPPORT:\${NC} $ADMIN_NAME ($ADMIN_EMAIL)"
    echo ""
    echo -e "  \${CYAN}THOUGHT OF THE DAY:\${NC}"
    echo -e "  \${WHITE}\" \$TODAY_QUOTE \"\${NC}"
    echo ""
fi
EOF

# --- WATCHDOG UPGRADE ---
echo "🛡️ Upgrading Cron Watchdog with Service Auto-Recovery..."
# Only restart if the service is actually installed/enabled
sed -i '/# Re-gather stats/a # Service Watchdog\nif systemctl list-unit-files | grep -q "isc-dhcp-server.service"; then systemctl is-active --quiet isc-dhcp-server || systemctl restart isc-dhcp-server 2>/dev/null; fi\nif systemctl list-unit-files | grep -q "bind9.service"; then systemctl is-active --quiet bind9 || systemctl restart bind9 2>/dev/null; fi' "$CRON_SCRIPT"
chmod +x "$MOTD_SCRIPT"

# 7. Smart Dynamic Prompt
echo "Setting up Smart Dynamic Prompt..."
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd $REAL_USER | cut -d: -f6)

BASHRC_SNIPPET=$(cat <<'EOF'

# --- B1SWA Universal Smart Prompt (Pure ASCII) ---
set_prompt() {
    local EXIT="$?"
    local G='\[\033[1;32m\]'
    local R='\[\033[1;31m\]'
    local W='\[\033[00;37m\]'
    local B='\[\033[01;34m\]'
    local Y='\[\033[01;33m\]'
    local NC='\[\033[00m\]'
    local UC=$G
    [ "$EUID" -eq 0 ] && UC=$R
    local SSH_INFO=""
    [ -n "$SSH_CONNECTION" ] && SSH_INFO="(SSH) "
    PS1="${SSH_INFO}${UC}\u${W}@${B}\h${NC}:${Y}\w${NC} \$ "
}
PROMPT_COMMAND=set_prompt
EOF
)

for target in "$USER_HOME/.bashrc" "/root/.bashrc"; do
    if [ -f "$target" ]; then
        # Remove any existing B1SWA prompt blocks to avoid duplicates
        sed -i '/# --- B1SWA Universal/,/PROMPT_COMMAND=set_prompt/d' "$target"
        echo "$BASHRC_SNIPPET" >> "$target"
    fi
done

# 8. Global Console Clean Up (Ultimate Suppression)
echo "🧹 Performing global console silence..."
if [ -d /etc/update-motd.d/ ]; then
    find /etc/update-motd.d/ -type f -exec chmod -x {} + 2>/dev/null
fi
# Clear all motd files
[ -f /etc/motd ] && truncate -s 0 /etc/motd
[ -f /etc/legal ] && truncate -s 0 /etc/legal
[ -f /run/motd.dynamic ] && truncate -s 0 /run/motd.dynamic 2>/dev/null

# Disable Ubuntu MOTD news service globally
[ -f /etc/default/motd-news ] && sed -i 's/ENABLED=1/ENABLED=0/' /etc/default/motd-news 2>/dev/null
command -v systemctl &>/dev/null && systemctl disable --now motd-news.timer 2>/dev/null

# Specifically target landscape-sysinfo (the one in your screenshot)
[ -f /var/lib/landscape/landscape-sysinfo.cache ] && rm -f /var/lib/landscape/landscape-sysinfo.cache 2>/dev/null

# GLOBAL PAM SILENCE: Disable MOTD in all login methods (SSH, TTY, etc.)
for pam_file in /etc/pam.d/sshd /etc/pam.d/login /etc/pam.d/su; do
    if [ -f "$pam_file" ]; then
        sed -i 's/^session.*optional.*pam_motd.so/#&/' "$pam_file" 2>/dev/null
    fi
done

# --- Final Completion ---
whiptail --title "Minimalist Branding Complete" --msgbox "System upgraded with Minimalist Professional Identity!\n\nStatus:\n- Global Console Silence Active.\n- Symmetrical Professional Banners Applied.\n- Internet Time Sync (NTP) Enabled." 12 70

echo -e "✅ ${GREEN}Minimalist Branding Deployment Complete!${NC}"
# 9. Internet Time Synchronization (NTP)
echo "🌐 Synchronizing system time with internet (NTP)..."
if command -v timedatectl &>/dev/null; then
    # Ensure systemd-timesyncd is installed on Debian/Ubuntu
    if command -v apt-get &>/dev/null; then
        apt-get install -y -qq systemd-timesyncd &>/dev/null
    fi
    
    # Enable and start time sync
    timedatectl set-ntp true
    
    # Force a restart of the service to trigger immediate sync
    if command -v systemctl &>/dev/null; then
        systemctl restart systemd-timesyncd &>/dev/null
    fi
    
    echo "✅ System time synchronized with global internet time."
else
    echo "[WARNING] timedatectl not found. Manual time sync might be required."
fi

echo ""
echo "##############################################################################"
echo "##                                                                          ##"
echo "##             BRANDING DEPLOYMENT COMPLETE | ENJOY YOUR TERMINAL           ##"
echo "##                                                                          ##"
echo "##############################################################################"
echo ""
