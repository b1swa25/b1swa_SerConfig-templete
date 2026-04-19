# DHCP Debugging & Troubleshooting Guide

This guide provides essential commands for testing, validating, and debugging DHCP server configurations on Linux, specifically tailored for ISC DHCP Server setups.

## 1. DHCP Client Testing

These tools are used to test the DHCP server's responsiveness and verify that clients can successfully obtain IP addresses.

| Command | Description |
| :--- | :--- |
| `sudo dhclient -v <interface>` | Request an IP address in verbose mode (shows the DORA process). |
| `sudo dhclient -r <interface>` | Release the current DHCP lease on a specific interface. |
| `sudo dhcping -c <client_ip> -s <server_ip> -h <mac>` | Check if the DHCP server responds without changing your IP. |
| `nmap --script broadcast-dhcp-discover` | Scan the network to discover all active DHCP servers. |

---

## 2. Configuration Validation

Before restarting the DHCP service, always validate your configuration files to catch syntax errors that could prevent the service from starting.

| Command | Description |
| :--- | :--- |
| `sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf` | Test the syntax of the main configuration file. |
| `cat /var/lib/dhcp/dhcpd.leases` | View the active lease database to see assigned IPs. |
| `sudo truncate -s 0 /var/lib/dhcp/dhcpd.leases` | Clear all current leases (stop service first). |

---

## 3. Service & Log Monitoring

Check the status of the service and tail logs to see real-time errors, discovery requests, and lease assignments.

| Command | Description |
| :--- | :--- |
| `systemctl status isc-dhcp-server` | Check if the DHCP service is running or has failed. |
| `journalctl -u isc-dhcp-server -f` | Tail DHCP logs in real-time to monitor client requests. |
| `tail -f /var/log/syslog | grep dhcpd` | Alternative way to view DHCP server activity. |
| `systemctl restart isc-dhcp-server` | Restart the service to apply configuration changes. |

---

## 4. Network & Port Checking

Ensure the DHCP server is actually listening on the correct ports (UDP 67/68) and that the firewall isn't blocking traffic.

| Command | Description |
| :--- | :--- |
| `sudo lsof -i :67` | Verify that `dhcpd` is listening on the DHCP server port. |
| `sudo tcpdump -i <iface> port 67 or 68 -n` | Capture raw DHCP packets to verify network traffic. |
| `sudo ufw allow 67/udp` | Ensure the firewall allows incoming DHCP discovery requests. |
| `ip addr show <iface>` | Verify the interface has a static IP in the correct subnet. |

---

## 📄 License & Copyright
This guide is created and maintained by **b1swa**.

**Copyright © b1swa**
All rights reserved.
