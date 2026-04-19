# Minimalist Professional Terminal Branding Suite

![Terminal Branding Showcase](https://github.com/b1swa25/b1swa_Server-templete/blob/main/Banner/assets/image3.png)

A professional, distraction-free branding and monitoring suite for Linux terminal environments. This project automates the deployment of high-impact ASCII banners, dynamic system health dashboards (MOTD), and security-aware self-healing logic.

## 🚀 Key Features

- **Automated System Branding**: Replaces standard login text with a symmetrical, blue-bordered "Management Platform" identity.
- **Self-Healing & Service Monitoring**:
  - **30-Second Watchdog**: A background pulse checks every 30 seconds if DHCP and DNS services are active.
  - **Auto-Recovery**: Automatically executes a restart command if any critical network service (Bind9/ISC-DHCP) crashes.
- **Live Dynamic Dashboard**:
  - **Pre-Login Monitoring**: System stats (RAM, CPU, IP) are visible on the login screen before entering credentials.
  - **High-Frequency Refresh**: Custom cron jobs ensure pre-login stats are never more than 30 seconds old.
- **Security Audit & Hardening**:
  - **Intrusion Detection**: Displays a total count of failed login attempts for the current 24-hour period.
  - **Last-Login Tracking**: Identifies the IP and timestamp of the last successful connection.
- **Precision Time Management**:
  - **Global NTP Sync**: Automates synchronization for 100% log accuracy.
  - **Localized Timezone**: Pre-configured for Bhutan (+06:00) with a live [SYNCED] status badge.
- **Smart Administration Prompt**: Pure ANSI/ASCII rendering with SSH detection and root protection (Username turns Bold Red).

## 📊 Smart Visual Summary (Color Talk)

The system uses a **Traffic Light System** to alert you to issues at a glance:

![Color Logic](https://github.com/b1swa25/b1swa_Server-templete/blob/main/Banner/assets/image8.png)

- **Health Stats (Disk/RAM)**:
  - **Green**: Safe usage.
  - **Yellow**: Caution (above 70%).
  - **Bold Red**: Critical (above 90%).
- **Security Tracker**:
  - **Green**: No failed logins today.
  - **Bold Red**: Unauthorized attempts detected.
- **Bash Prompt**:
  - **✓ (Green)**: Last command worked perfectly.
  - **✘ (Red)**: Last command failed.

## 🛠️ Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Banner
   ```

2. **Run the setup script**:
   ```bash
   sudo ./setup_branding.sh
   ```

## 📁 System Changes & Impact

Running the setup script will affect the following system locations:

### Created Files
- `/etc/branding/`: Core directory for branding assets.
- `/usr/local/bin/refresh_banner.sh`: Background script for dynamic banner updates.
- `/etc/profile.d/99-branding.sh`: The logic for the post-login dashboard.

### Modified Files
- `/etc/issue` & `/etc/issue.net`: Replaced with the custom ASCII banner.
- `~/.bashrc` & `/root/.bashrc`: Appended with the B1SWA Smart Prompt.
- `/etc/pam.d/sshd`, `/etc/pam.d/login`: Standard MOTD suppressed.
- `/etc/default/motd-news`: Disabled news updates.

## 🖥️ System Metadata
- **Deployment User**: b1swa
- **Environment**: myLab
- **Standard**: Bhutan-standard NTP synchronization (+06:00)

---
**Copyright © B1SWA | Professional Network Management Platform**
