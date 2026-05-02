# Universal Manual Setup Guide: Mail Server (Roundcube Edition)
**Engine:** Postfix, Dovecot, Roundcube, MariaDB
**Supported OS:** Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux
**Author:** © b1swa
**Contact:** sandipbiswa10@gmail.com

---

If you prefer not to use the automated bash script, follow this step-by-step manual guide. It covers the specific commands required for all three major Linux families.

> [!TIP]
> **Best Practice:** It is highly recommended to perform this manual setup on a fresh Virtual Machine (VM) to avoid conflicts with previously installed web servers or databases.

> [!IMPORTANT]
> **Placeholder Values:** Throughout this guide, you will see dummy values like `b1swa.local` (domain), `127.0.0.0/8` (networks), and `b1swa` (username). **You must replace these** with your own actual domain name, allowed IP networks, and desired usernames wherever they appear!

---

## Phase 1: Install Required Packages

First, ensure your package lists are updated and install the necessary core components.

### Debian / Ubuntu / Mint
```bash
sudo apt update
sudo apt install postfix dovecot-core dovecot-imapd dovecot-pop3d apache2 mariadb-server php libapache2-mod-php php-mysql php-mbstring php-intl php-xml php-curl unzip wget curl
```
> [!NOTE]
> During the Postfix installation prompt on Debian-based systems, select **"Internet Site"** and enter your domain name (e.g., **replace** `b1swa.local` with your actual domain name).

### RHEL / CentOS / Fedora
```bash
sudo dnf install epel-release
sudo dnf install postfix dovecot httpd mariadb-server php php-mysqlnd php-mbstring php-intl php-xml php-json curl unzip wget
```

### Arch Linux
```bash
sudo pacman -Sy postfix dovecot apache mariadb php php-apache php-sqlite sqlite unzip wget
```

---

## Phase 2: Configure Postfix (SMTP Engine)

1. Open the Postfix main configuration file (Same for all OS):
   ```bash
   sudo nano /etc/postfix/main.cf
   ```
2. Replace or modify the contents to match your domain:
   ```ini
   myhostname = mail.b1swa.local
   mydomain = b1swa.local
   myorigin = $mydomain
   inet_interfaces = all
   inet_protocols = all
   mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
   mynetworks = 127.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 10.0.0.0/8
   home_mailbox = Maildir/
   ```
   > [!NOTE]
   > **Replace:** Ensure you replace `b1swa.local` with your actual domain name, and replace the `mynetworks` list with the actual IP ranges allowed in your network!

   > [!WARNING]
   > **Security Warning:** Pay close attention to `mynetworks`. If you accidentally set this to `0.0.0.0/0`, you will create an "Open Relay", meaning anyone on the internet can use your server to send spam!

3. Set up the `postmaster` alias to receive server errors:
   ```bash
   echo "postmaster: admin@b1swa.local" | sudo tee -a /etc/aliases
   sudo newaliases
   ```
   > [!NOTE]
   > **Replace:** Replace `admin@b1swa.local` with your actual admin email address.

---

## Phase 3: Configure Dovecot (IMAP/POP3 Engine)

The configuration paths are identical across all distributions.

1. Enable the correct mail protocols:
   ```bash
   sudo sed -i 's/#protocols = imap pop3 lmtp submission/protocols = imap pop3 lmtp/g' /etc/dovecot/dovecot.conf
   ```
2. Set the physical mail storage location to use the `Maildir/` format:
   ```bash
   sudo sed -i 's|#mail_location =|mail_location = maildir:~/Maildir|g' /etc/dovecot/conf.d/10-mail.conf
   ```
3. Allow plaintext authentication:
   ```bash
   sudo sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g' /etc/dovecot/conf.d/10-auth.conf
   sudo sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/g' /etc/dovecot/conf.d/10-auth.conf
   ```
   > [!CAUTION]
   > Enabling plaintext authentication is required here because Roundcube connects to Dovecot internally over `localhost:143`. If you ever expose Port 143 to the public internet, you must configure SSL/TLS certificates, otherwise passwords will be sent in clear text.

---

## Phase 4: Configure the Firewall

Open the standard mail and web ports.

### Debian / Ubuntu (Using UFW)
```bash
sudo ufw allow 25/tcp   # SMTP
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 110/tcp  # POP3
sudo ufw allow 143/tcp  # IMAP
```

### RHEL / CentOS / Fedora (Using Firewalld)
```bash
sudo firewall-cmd --permanent --zone=public --add-port=25/tcp
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --permanent --zone=public --add-port=110/tcp
sudo firewall-cmd --permanent --zone=public --add-port=143/tcp
sudo firewall-cmd --reload
```
> [!TIP]
> If you are setting this up strictly for internal lab testing and not connecting to it from an external machine, you only strictly need Port 80 open (as Roundcube communicates with the mail ports internally).

---

## Phase 5: Setup MariaDB for Roundcube

1. **(Arch Linux Only)** Initialize the database directory first:
   ```bash
   sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
   ```
2. Ensure MariaDB is running (All OS):
   ```bash
   sudo systemctl start mariadb
   sudo systemctl enable mariadb
   ```
3. Enter the MySQL shell as root and run the following queries:
   ```sql
   sudo mysql -u root

   -- Inside the MySQL Shell:
   CREATE DATABASE roundcubemail /*!40101 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;
   CREATE USER 'roundcube'@'localhost' IDENTIFIED BY 'roundcubepass';
   GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
   FLUSH PRIVILEGES;
   EXIT;
   ```
   > [!NOTE]
   > **Replace:** In a production environment, you must replace `'roundcubepass'` with a strong, random password.

---

## Phase 6: Install Roundcube Webmail

1. Download and extract the Roundcube source:
   ```bash
   sudo mkdir -p /usr/share/roundcube
   cd /usr/share/roundcube
   sudo wget https://github.com/roundcube/roundcubemail/releases/download/1.6.15/roundcubemail-1.6.15-complete.tar.gz
   sudo tar -xzf roundcubemail-1.6.15-complete.tar.gz --strip-components=1
   sudo rm roundcubemail-1.6.15-complete.tar.gz
   ```
2. Set directory ownership so the Web Server can read/write.
   **Debian/Ubuntu:**
   ```bash
   sudo chown -R www-data:www-data /usr/share/roundcube/temp
   sudo chown -R www-data:www-data /usr/share/roundcube/logs
   ```
   **RHEL/CentOS:**
   ```bash
   sudo chown -R apache:apache /usr/share/roundcube/temp
   sudo chown -R apache:apache /usr/share/roundcube/logs
   ```
   **Arch Linux:**
   ```bash
   sudo chown -R http:http /usr/share/roundcube/temp
   sudo chown -R http:http /usr/share/roundcube/logs
   ```
3. Import the initial database schema:
   ```bash
   sudo mysql -u root roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql
   ```
4. Create the Roundcube configuration file:
   ```bash
   sudo nano /usr/share/roundcube/config/config.inc.php
   ```
   *Paste the following contents:*
   ```php
   <?php
   $config = [];
   $config['db_dsnw'] = 'mysql://roundcube:roundcubepass@localhost/roundcubemail';
   $config['imap_host'] = 'localhost:143';
   $config['smtp_host'] = 'localhost:25';
   $config['smtp_user'] = '';
   $config['smtp_pass'] = '';
   $config['support_url'] = 'http://b1swa.local/';
   $config['product_name'] = 'b1swa Private Limited Webmail';
   $config['des_key'] = 'random_24_character_string_here';
   $config['plugins'] = [];
   $config['language'] = 'en_US';
   ```
   > [!NOTE]
   > **Replace:** 
   > - Replace `roundcubepass` with the database password you set in Phase 5.
   > - Replace `b1swa.local` with your actual domain URL.
   > - Replace `b1swa Private Limited Webmail` with your organization's name.
   > - Replace `random_24_character_string_here` with a random 24-character string (required for encryption).

---

## Phase 7: Configure Web Server & Restart Services

Create a Web Server alias so that `http://<IP>/webmail` resolves correctly.

### Debian / Ubuntu
1. Create the config:
   ```bash
   sudo nano /etc/apache2/sites-available/roundcube.conf
   ```
2. Paste the Alias mapping:
   ```apache
   Alias /webmail /usr/share/roundcube
   <Directory /usr/share/roundcube>
       Options -Indexes
       AllowOverride All
       Require all granted
   </Directory>
   ```
3. Enable and restart:
   ```bash
   sudo a2ensite roundcube
   sudo systemctl restart apache2 postfix dovecot
   ```

### RHEL / CentOS / Fedora
1. Create the config:
   ```bash
   sudo nano /etc/httpd/conf.d/roundcube.conf
   ```
2. Paste the exact same Alias mapping as above.
3. Restart services:
   ```bash
   sudo systemctl restart httpd postfix dovecot
   ```

### Arch Linux
1. Create the config:
   ```bash
   sudo nano /etc/httpd/conf/extra/roundcube.conf
   ```
2. Paste the exact same Alias mapping as above.
3. Include the config in the main `httpd.conf`:
   ```bash
   echo "Include conf/extra/roundcube.conf" | sudo tee -a /etc/httpd/conf/httpd.conf
   ```
4. Restart services:
   ```bash
   sudo systemctl restart httpd postfix dovecot
   ```

---

## Phase 8: Create Mail Users

Finally, create your test users. Linux system users are automatically treated as Mail users by Postfix/Dovecot.

```bash
sudo useradd -m -s /bin/bash b1swa
sudo passwd b1swa
```
> [!NOTE]
> **Replace:** Replace `b1swa` with the username you actually want to create (e.g., `john`, `admin`).
>
> Even though you created the user, the physical `~/Maildir/` folder will not be created in their home directory until they receive their very first email!

**You are done!** Open `http://<your-server-ip>/webmail` in your browser and log in with your newly created user!

---

## Phase 9: Testing & Local DNS (Optional)

If you chose a fake local domain (like `b1swa.local`) and you want to type `http://b1swa.local/webmail` into your browser instead of typing the IP address, you must configure your computer's DNS to know where that domain lives.

To do this, edit the `hosts` file on the computer where the web browser is running.

**On Linux or Mac (The Client Machine):**
```bash
sudo nano /etc/hosts
```

**On Windows (The Client Machine):**
Open Notepad as Administrator and edit: `C:\Windows\System32\drivers\etc\hosts`

Add the following line to the bottom of the file:
```text
192.168.1.100   b1swa.local   mail.b1swa.local
```
> [!NOTE]
> **Replace:** Replace `192.168.1.100` with the actual IP address of your Mail Server VM, and replace `b1swa.local` with your actual domain.

Save the file. Now, your browser will successfully resolve `http://b1swa.local/webmail` straight to your new Mail Server!
