# Universal Mail Server Debugging & Troubleshooting Guide
**Engine:** Postfix, Dovecot, Roundcube, MariaDB
**Supported OS:** Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux
**Author:** © b1swa
**Contact:** sandipbiswa10@gmail.com

---

## 1. Quick Status Checks
Whenever you encounter an issue, the first step is to verify that all core services are actively running. Because this is a universal script, your web server service name depends on your OS!

```bash
# Check Postfix (SMTP / Sending)
sudo systemctl status postfix

# Check Dovecot (IMAP/POP3 / Receiving & Auth)
sudo systemctl status dovecot

# Check MariaDB (Roundcube Database)
sudo systemctl status mariadb

# Check Web Server (Roundcube Interface)
sudo systemctl status apache2  # For Debian/Ubuntu
sudo systemctl status httpd    # For RHEL/CentOS/Arch
```
*If any service shows `failed` or `inactive`, try restarting it with `sudo systemctl restart <service_name>`.*

---

## 2. Reading the Logs (The Holy Grail)
If the services are running but mail isn't working, the logs will tell you exactly why.

### Postfix & Dovecot (Mail Routing & Authentication)
**Debian/Ubuntu:**
```bash
sudo tail -f /var/log/mail.log
```
**RHEL/CentOS/Fedora:**
```bash
sudo tail -f /var/log/maillog
```

### Web Server & PHP (Roundcube Loading Issues)
**Debian/Ubuntu:**
```bash
sudo tail -f /var/log/apache2/error.log
```
**RHEL/CentOS/Fedora:**
```bash
sudo tail -f /var/log/httpd/error_log
```

### Roundcube Internal Errors
If Roundcube loads but gives a specific error (e.g., "Connection to storage server failed"):
```bash
sudo tail -f /usr/share/roundcube/logs/errors.log
```

---

## 3. Common Issues & Solutions

### Issue A: "Connection to storage server failed" in Roundcube
**Cause:** Roundcube cannot communicate with Dovecot over IMAP (Port 143), or DB credentials failed.
**Fix:** Ensure Dovecot is running (`systemctl status dovecot`) and `disable_plaintext_auth = no` is set in `/etc/dovecot/conf.d/10-auth.conf`.

### Issue B: Emails are stuck in the queue and not delivering
**Cause:** Postfix cannot resolve the destination domain, or DNS is improperly configured.
**Fix:**
1. Check the queue: `sudo mailq`
2. Force a queue flush: `sudo postqueue -f`

### Issue C: Cannot access `http://<IP>/webmail` externally
**Cause:** The firewall is blocking port 80.
**Fix:**
**Debian/Ubuntu (UFW):**
```bash
sudo ufw status numbered
sudo ufw allow 80/tcp
```
**RHEL/CentOS (Firewalld):**
```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload
```

### Issue D: Authentication Failed when logging into Roundcube
**Cause:** You typed the wrong password, or the Linux user doesn't exist.
**Fix:** Remember that Roundcube users are system users. Reset the user's password locally: `sudo passwd <username>`

---

## 4. Helpful Commands for Testing

### Test IMAP Login Manually via Telnet
```bash
telnet localhost 143
# Type this once connected:
a1 LOGIN yourusername yourpassword
```

### Test SMTP Manually via Telnet
```bash
telnet localhost 25
# Type this once connected:
EHLO localhost
```

---

## 5. Exhaustive List of Script Modifications (Universal)

If you need to manually revert or tweak what the `setup_mail_server_universal.sh` script did, here is an exhaustive list of **everything** it touches based on your OS:

### 1. System Packages Installed (Dynamically via `apt`, `dnf`, or `pacman`)
- `postfix`, `dovecot` (or `dovecot-core`, `dovecot-imapd`, `dovecot-pop3d`)
- `apache2` (Debian) or `httpd` (RHEL) or `apache` (Arch)
- `mariadb-server` (Debian/RHEL) or `mariadb` (Arch)
- Various OS-specific PHP modules (`php-mysql`, `php-mbstring`, etc.)

### 2. Mail Configurations (Postfix & Dovecot)
- `/etc/postfix/main.cf`: Completely rewritten for your Domain.
- `/etc/aliases`: Appended with `postmaster: admin@yourdomain`.
- `/etc/dovecot/dovecot.conf`: Modified to enable `imap`, `pop3`, `lmtp`.
- `/etc/dovecot/conf.d/10-mail.conf`: Set to `maildir:~/Maildir`.
- `/etc/dovecot/conf.d/10-auth.conf`: Enabled `plain login`.

### 3. Firewall Rules
- **UFW (Ubuntu):** Ports 25, 80, 110, 143 allowed via `ufw allow`.
- **Firewalld (RHEL):** Ports 25, 80, 110, 143 allowed via `firewall-cmd`.

### 4. MariaDB (Database)
- Database Created: `roundcubemail`
- User Created: `roundcube` @ `localhost`

### 5. Roundcube Files & Directories
- `/usr/share/roundcube/`: The directory where the Roundcube app is extracted.
- `/usr/share/roundcube/temp` and `/logs`: Ownership recursively changed to `www-data` (Debian), `apache` (RHEL), or `http` (Arch).
- `/usr/share/roundcube/config/config.inc.php`: Master configuration file.

### 6. Web Server Aliases
- **Debian/Ubuntu**: `/etc/apache2/sites-available/roundcube.conf` (enabled via `a2ensite`).
- **RHEL/CentOS**: `/etc/httpd/conf.d/roundcube.conf`.
- **Arch Linux**: `/etc/httpd/conf/extra/roundcube.conf` (and `IncludeOptional` added to `httpd.conf`).

### 7. System Users
- Linux system users (`/etc/passwd`, `/etc/shadow`) and Home Directories (`/home/<username>/`) generated.
- `~/Maildir/`: Automatically generated for physical emails.
