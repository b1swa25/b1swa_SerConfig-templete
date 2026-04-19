# 🚀 Private DHCP Setup Tool (Native ISC DHCP)

![DHCP Banner](/home/b1swa/.gemini/antigravity/brain/38763a73-988b-488c-a3bf-082402957a91/dhcp_banner_1776532883027.png)

An advanced, interactive bash-driven suite designed to deploy and manage a **Native ISC DHCP Server** on Ubuntu/Debian systems. This tool streamlines the deployment process, handling everything from network interface binding to automated firewall orchestration.

---

## ✨ Premium Features

- **🏆 Industry Standard**: Powered by the robust and reliable ISC DHCP Server engine.
- **🔍 Intelligent Discovery**: Automatically scans system interfaces and suggests optimal IP ranges.
- **🎨 Interactive UX**: Guided configuration using professional `whiptail` terminal interfaces.
- **🛡️ Security First**: Integrated UFW (Uncomplicated Firewall) rules for seamless port management.
- **📈 Live Monitoring**: Visual progress tracking during the installation and service deployment phases.
- **📝 Automatic Backups**: Self-healing logic that preserves your existing configurations before modification.

---

## 📸 Visual Walkthrough

Experience the guided setup process through these interactive stages:

````carousel
![Welcome Screen](/home/b1swa/Downloads/Untitled%20Folder%202/DHCP/assets/image12.png)
<!-- slide -->
![Firewall Configuration](/home/b1swa/Downloads/Untitled%20Folder%202/DHCP/assets/image13.png)
<!-- slide -->
![Installation Success](/home/b1swa/Downloads/Untitled%20Folder%202/DHCP/assets/image7.png)
<!-- slide -->
![Client Lease Verification](/home/b1swa/Downloads/Untitled%20Folder%202/DHCP/assets/image9.png)
<!-- slide -->
![Windows Client Testing](/home/b1swa/Downloads/Untitled%20Folder%202/DHCP/assets/image11.png)
````

---

## 🏗️ System Impact & Audit

This tool performs the following modifications to ensure a "native" system integration. Review this section for security auditing purposes.

### 📂 Configuration & Data Paths
| Target Path | Action | Description |
| :--- | :--- | :--- |
| `/etc/dhcp/dhcpd.conf` | **Overwrite** | Main Configuration: Where subnets and ranges are defined. |
| `/etc/default/isc-dhcp-server` | **Modify** | Interface Settings: Tells the server which network card to use. |
| `/var/lib/dhcp/dhcpd.leases` | **Access** | Lease Database: Tracks IP assignments to client devices. |
| `/etc/dhcp/dhcpd.conf.bak.*` | **Create** | Timestamped backups generated before configuration changes. |

### 🛠️ System Services & Dependencies
- **Service**: `isc-dhcp-server.service` (Restarted and Enabled for boot persistence).
- **Packages**: Installs `isc-dhcp-server` and `isc-dhcp-client` via `apt-get`.
- **Ports**: Opens **67/UDP/TCP** and **68/UDP/TCP** in the system firewall (UFW).

---

## 🔍 Monitoring & Logs

To monitor the server in real-time or debug issues, use the following log locations:

- **System Log**: `/var/log/syslog` (Filtered for `dhcpd` events).
- **Service Journal**: `sudo journalctl -u isc-dhcp-server -f`
- **Active Leases**: `cat /var/lib/dhcp/dhcpd.leases`

---

## 🚀 Deployment Guide

### 1. Prerequisites
- **OS**: Ubuntu Server 20.04+ or Debian-based distributions.
- **Privileges**: Sudo/Root access required for system-level configuration.
- **Network**: A static IP configured on the target interface is highly recommended.

### 2. Execution
Run the interactive installer directly from the project directory:
```bash
sudo ./setup_private_dhcp_native.sh
```

---

## 🛠️ Troubleshooting & Diagnostics

If you encounter issues, refer to the **[DHCP Debugging Guide](file:///home/b1swa/Downloads/Untitled%20Folder%202/DHCP/dhcp_debugging_guide.md)** or use the following standard commands:

### Essential Health Checks
```bash
# Verify configuration syntax
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Check service status
sudo systemctl status isc-dhcp-server
```

### Common Resolution Matrix
| Symptom | Probable Cause | Resolution |
| :--- | :--- | :--- |
| **Service Failed** | Missing Subnet Declaration | Match `dhcpd.conf` subnet to your server's IP. |
| **Client No IP** | Firewall Obstruction | Ensure UFW allows ports 67/68. |
| **Interface Error** | Incorrect IFACE Name | Verify `INTERFACESv4` in `/etc/default/isc-dhcp-server`. |

---

## 📄 License & Integrity
Developed and maintained by **b1swa**.

**Copyright © 2024 b1swa**  
*All rights reserved. Secure, Native, and Professional Network Infrastructure.*
