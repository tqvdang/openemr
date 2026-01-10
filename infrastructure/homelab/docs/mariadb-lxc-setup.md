# MariaDB LXC Setup for OpenEMR in pve2

**Important**: OpenEMR requires MySQL/MariaDB, not PostgreSQL. This guide sets up a MariaDB LXC container.

## Container Specifications

- **Host**: pve2.trancloud.work (192.168.10.12)
- **Container Name**: openemr-db
- **Container IP**: 192.168.10.30
- **OS Template**: debian-12-standard
- **MariaDB Version**: 11.5
- **Storage**: 20GB

## Step 1: Create LXC Container via Proxmox Web UI

1. Login to pve2: https://pve2.trancloud.work
   - Username: root
   - Password: <PASSWORD_FROM_INFISICAL>

2. Click **Create CT** button

3. **General** tab:
   - Node: pve2
   - CT ID: 102 (or next available)
   - Hostname: openemr-db
   - Unprivileged container: ✓ (checked)
   - Password: <PASSWORD_FROM_INFISICAL>
   - Confirm password: <PASSWORD_FROM_INFISICAL>

4. **Template** tab:
   - Storage: local
   - Template: debian-12-standard (download if not available)

5. **Disks** tab:
   - Storage: local-lvm
   - Disk size: 20 GB

6. **CPU** tab:
   - Cores: 2

7. **Memory** tab:
   - Memory: 2048 MB
   - Swap: 512 MB

8. **Network** tab:
   - Name: eth0
   - Bridge: vmbr0
   - IPv4: Static
   - IPv4/CIDR: 192.168.10.30/24
   - Gateway: 192.168.10.1
   - IPv6: SLAAC

9. **DNS** tab:
   - DNS domain: trancloud.work
   - DNS servers: 192.168.10.1

10. **Confirm** and click **Finish**

## Step 2: Start Container and Install MariaDB

```bash
# SSH to pve2
ssh root@pve2.trancloud.work
# Password: <PASSWORD_FROM_INFISICAL>

# Start the container
pct start 102

# Enter the container
pct enter 102

# Update system
apt update && apt upgrade -y

# Install MariaDB server
apt install -y mariadb-server mariadb-client

# Install additional tools
apt install -y vim curl net-tools

# Secure MariaDB installation
mysql_secure_installation <<EOF

y
<PASSWORD_FROM_INFISICAL>
<PASSWORD_FROM_INFISICAL>
y
y
y
y
EOF
```

## Step 3: Create OpenEMR Database and User

```bash
# Still in the container
mysql -u root -p <<'EOF'
-- Password: <PASSWORD_FROM_INFISICAL>

-- Create database with utf8mb4 character set
CREATE DATABASE openemr_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Create user for OpenEMR
CREATE USER 'openemr_dev'@'%' IDENTIFIED BY '<DB_PASSWORD_FROM_INFISICAL>';

-- Grant all privileges
GRANT ALL PRIVILEGES ON openemr_dev.* TO 'openemr_dev'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Show databases
SHOW DATABASES;

-- Exit
EXIT;
EOF
```

## Step 4: Configure MariaDB for Remote Connections

```bash
# Edit MariaDB configuration
vim /etc/mysql/mariadb.conf.d/50-server.cnf

# Find and modify:
[mysqld]
bind-address = 0.0.0.0  # Change from 127.0.0.1 to 0.0.0.0

# Add these optimizations for OpenEMR
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
max_connections = 200
max_allowed_packet = 64M
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M

# Save and exit (ESC, :wq)

# Restart MariaDB
systemctl restart mariadb

# Verify MariaDB is running
systemctl status mariadb

# Check if listening on all interfaces
netstat -an | grep 3306
# Should show: 0.0.0.0:3306

# Exit container
exit
```

## Step 5: Test Connection from k3s Master

```bash
# SSH to k3s master
ssh root@192.168.10.60

# Install MariaDB client
apt update && apt install -y mariadb-client

# Test connection
mysql -h 192.168.10.30 -u openemr_dev -p openemr_dev
# Password: <DB_PASSWORD_FROM_INFISICAL>

# If successful, you'll see the MariaDB prompt
# List databases
SHOW DATABASES;

# Exit
EXIT;
```

## Step 6: Enable Autostart and Configure Firewall

```bash
# On pve2 host
ssh root@pve2.trancloud.work

# Enable container autostart
pct set 102 -onboot 1

# Verify autostart is enabled
pct config 102 | grep onboot

# Optional: Configure firewall rules in container
pct enter 102

# If ufw is installed, allow MySQL
# apt install -y ufw
# ufw allow from 192.168.10.0/24 to any port 3306
# ufw enable

exit
```

## Verification Checklist

- [ ] Container created and running
- [ ] MariaDB installed and running
- [ ] Database `openemr_dev` created with utf8mb4 charset
- [ ] User `openemr_dev` created with correct privileges
- [ ] bind-address set to 0.0.0.0
- [ ] Remote connections allowed from 192.168.10.0/24
- [ ] Connection test from k3s master successful
- [ ] Autostart enabled

## Connection Details for Kubernetes

Update these values in `infrastructure/homelab/k8s/overlays/dev/secrets.yaml` and `configmap.yaml`:

```yaml
# configmap.yaml
db_host: "192.168.10.30"
db_port: "3306"  # MySQL/MariaDB port, not 5432

# secrets.yaml
db_root_password: "<PASSWORD_FROM_INFISICAL>"
db_user: "openemr_dev"
db_password: "<DB_PASSWORD_FROM_INFISICAL>"
```

## Troubleshooting

### Cannot Connect Remotely

```bash
# Check if MariaDB is listening on all interfaces
pct enter 102
netstat -tlnp | grep 3306
# Should show: 0.0.0.0:3306

# Check bind-address
grep bind-address /etc/mysql/mariadb.conf.d/50-server.cnf

# Check user grants
mysql -u root -p
SHOW GRANTS FOR 'openemr_dev'@'%';
```

### Access Denied

```bash
# Verify user exists and has correct host
mysql -u root -p
SELECT User, Host FROM mysql.user WHERE User='openemr_dev';

# Should show: openemr_dev | %

# Recreate user if needed
DROP USER 'openemr_dev'@'%';
CREATE USER 'openemr_dev'@'%' IDENTIFIED BY '<DB_PASSWORD_FROM_INFISICAL>';
GRANT ALL PRIVILEGES ON openemr_dev.* TO 'openemr_dev'@'%';
FLUSH PRIVILEGES;
```

### Container Won't Start

```bash
# Check container status on pve2
pct status 102

# View container logs
pct enter 102
journalctl -xe

# Check MariaDB logs
tail -f /var/log/mysql/error.log
```

## Security Recommendations

- Change default passwords in production
- Use SSL/TLS for database connections
- Restrict access to specific IP addresses
- Regular backups using `mysqldump` or Proxmox backup
- Keep MariaDB updated

## Backup Commands

```bash
# Full database backup
mysqldump -u root -p openemr_dev > /tmp/openemr_dev_backup_$(date +%Y%m%d).sql

# Compressed backup
mysqldump -u root -p openemr_dev | gzip > /tmp/openemr_dev_backup_$(date +%Y%m%d).sql.gz

# Restore from backup
mysql -u root -p openemr_dev < /tmp/openemr_dev_backup_20240101.sql
```

## Performance Tuning

For better performance with OpenEMR, add to `/etc/mysql/mariadb.conf.d/50-server.cnf`:

```ini
[mysqld]
# Performance tuning for OpenEMR
innodb_buffer_pool_size = 1G  # 50-70% of available RAM
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
query_cache_type = 1
query_cache_size = 128M
tmp_table_size = 128M
max_heap_table_size = 128M
```

After changes, restart MariaDB:
```bash
systemctl restart mariadb
```
