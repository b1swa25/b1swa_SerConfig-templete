# 🌐 Native Private DNS (BIND9) Deployment Suite

![DNS Branding](https://github.com/b1swa25/b1swa_Server-templete/blob/main/DNS/assets/banner.png)

A professional, native Linux DNS configuration suite designed for automated deployment of private network services. This suite leverages **BIND9** to provide robust forward and reverse DNS resolution with a focus on performance, security, and ease of management.

---

## 🚀 Overview
This project automates the setup of a private DNS environment on Linux. It handles everything from package installation and conflict resolution (systemd-resolved) to the generation of dynamic zone files and firewall configuration.

### 🛠️ Core Components
| File | Role | Description |
| :--- | :--- | :--- |
| `setup_private_dns_native.sh` | **Engine** | Interactive Bash script for automated deployment. |
| `named.conf.local` | **Config** | Local zone declarations for BIND9. |
| `db.b1swa.local` | **Template** | Forward lookup zone database records. |
| `db.reverse` | **Template** | Reverse lookup zone database records. |
| `dns_debugging_guide.md` | **Support** | Comprehensive guide for troubleshooting. |

---

## 🎯 System Targets & Impact
The deployment script "targets" specific system directories to transition from a local configuration to a live network service:

### 📁 Configuration Targets
*   **`/etc/bind/`**: The primary target for service configuration.
*   **`/etc/bind/zones/`**: Dedicated directory created for custom zone databases.
*   **`/etc/systemd/resolved.conf`**: Modified to disable port 53 conflicts (DNSStubListener).

### ⚙️ Service Impact
*   **Package Installation**: Installs `bind9`, `bind9utils`, and `bind9-doc`.
*   **Firewall Rules**: Automatically updates **UFW** to allow traffic on Port 53 (UDP/TCP).
*   **Systemd Management**: Enables and restarts the `named` and `systemd-resolved` services.

---

## 📦 Installation
To deploy the DNS suite, execute the following command with root privileges:

```bash
sudo bash setup_private_dns_native.sh
```

### 📋 Prerequisites
- **OS**: Ubuntu/Debian-based Linux distribution.
- **Tools**: `whiptail` (for the interactive UI).
- **Access**: Root or sudo privileges are required for system modifications.

---

## 🔍 Verification
After deployment, verify the service status and resolution:

```bash
# Check service status
systemctl status named

# Test local resolution
dig @localhost b1swa.local

# Check configuration syntax
named-checkconf
```

![Verification Test](https://github.com/b1swa25/b1swa_Server-templete/blob/main/DNS/assets/verification_test.png)

---

## 🛡️ Support & Copyright
**Author**: b1swa  
**Contact**: sandipbiswa10@gmail.com  
**Copyright**: © 2026 b1swa. All rights reserved.

> [!IMPORTANT]
> Always review the `dns_debugging_guide.md` if you encounter resolution issues or port conflicts during setup.
