# DNS Debugging & Troubleshooting Guide

This guide provides essential commands for testing, validating, and debugging DNS configurations on Linux, specifically tailored for BIND9 setups.

## 1. DNS Resolution Testing

These tools are used to query DNS servers and verify that records are being served correctly.

| Command | Description |
| :--- | :--- |
| `dig @localhost b1swa.local` | Query your local DNS server for a specific domain. |
| `dig -x 192.168.1.10` | Perform a reverse lookup (PTR record). |
| `dig @localhost b1swa.local ANY` | Retrieve all available records for the domain. |
| `nslookup b1swa.local localhost` | A simpler tool for quick resolution checks. |
| `host b1swa.local` | A concise way to check IP mappings. |

---

## 2. Configuration Validation

Before restarting the DNS service, always validate your configuration files to catch syntax errors.

| Command | Description |
| :--- | :--- |
| `named-checkconf` | Checks the syntax of the main configuration files (e.g., `named.conf`). No output means success. |
| `named-checkzone b1swa.local db.b1swa.local` | Validates a specific zone file for errors. |
| `named-checkzone 1.168.192.in-addr.arpa db.reverse` | Validates a reverse zone file. |

---

## 3. Service & Log Monitoring

Check the status of the service and tail logs to see real-time errors or query logs.

| Command | Description |
| :--- | :--- |
| `systemctl status named` | Check if the BIND service is running. |
| `journalctl -u named -f` | Tail the BIND logs in real-time (very useful for debugging). |
| `rndc reload` | Reload the configuration without restarting the service. |
| `rndc status` | Get detailed statistics and status from the BIND server. |

---

## 4. Network & Port Checking

Ensure the DNS server is actually listening on the correct ports (UDP/TCP 53).

| Command | Description |
| :--- | :--- |
| `ss -tunlp | grep :53` | Verify BIND is listening on Port 53 (UDP and TCP). |
| `netstat -uap | grep named` | Alternative to `ss` for checking port bindings. |
| `nmap -sU -p 53 localhost` | Scan the local machine to see if the UDP port is open. |

---

## 5. Local Resolver Management

If you are testing from the same machine, you might need to manage the local system resolver.

| Command | Description |
| :--- | :--- |
| `resolvectl status` | See which DNS servers your system is currently using. |
| `resolvectl flush-caches` | Clear the local DNS cache if you suspect stale results. |
| `cat /etc/resolv.conf` | Check the legacy resolver configuration file. |
