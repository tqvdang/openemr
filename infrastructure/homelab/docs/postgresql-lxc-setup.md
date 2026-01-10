# PostgreSQL LXC Setup for OpenEMR in pve2

This guide documents how to create a PostgreSQL LXC container in pve2 for the OpenEMR dev environment.

## Container Specifications

- **Host**: pve2.trancloud.work (192.168.10.12)
- **Container Name**: openemr-db
- **Container IP**: 192.168.10.30
- **OS Template**: debian-12-standard
- **PostgreSQL Version**: 15
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

## Step 2: Start Container and Install PostgreSQL

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

# Install PostgreSQL 15
apt install -y postgresql-15 postgresql-contrib-15

# Install additional tools
apt install -y vim curl net-tools

# Exit container
exit
```

## Step 3: Configure PostgreSQL

```bash
# Enter container again
pct enter 102

# Switch to postgres user
su - postgres

# Create database and user for OpenEMR dev
psql <<EOF
-- Create database
CREATE DATABASE openemr_dev;

-- Create user with password
CREATE USER openemr_dev WITH PASSWORD '<DB_PASSWORD_FROM_INFISICAL>';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE openemr_dev TO openemr_dev;

-- Connect to database and grant schema privileges
\c openemr_dev
GRANT ALL ON SCHEMA public TO openemr_dev;

-- Exit
\q
EOF

# Exit postgres user
exit
```

## Step 4: Configure PostgreSQL for Remote Connections

```bash
# Edit postgresql.conf
vim /etc/postgresql/15/main/postgresql.conf

# Find and modify:
listen_addresses = '*'  # Allow connections from all interfaces

# Edit pg_hba.conf
vim /etc/postgresql/15/main/pg_hba.conf

# Add at the end:
# Allow connections from k3s cluster
host    openemr_dev     openemr_dev     192.168.10.0/24     scram-sha-256
# Allow connections from anywhere in the local network (for testing)
host    all             all             192.168.10.0/24     scram-sha-256

# Restart PostgreSQL
systemctl restart postgresql

# Verify PostgreSQL is running
systemctl status postgresql

# Exit container
exit
```

## Step 5: Test Connection from k3s Master

```bash
# SSH to k3s master
ssh root@192.168.10.60

# Install PostgreSQL client
apt update && apt install -y postgresql-client

# Test connection
psql -h 192.168.10.30 -U openemr_dev -d openemr_dev

# You should be prompted for password: <DB_PASSWORD_FROM_INFISICAL>
# If successful, you'll see the psql prompt

# List databases
\l

# Exit
\q
```

## Step 6: Enable Autostart

```bash
# On pve2 host
ssh root@pve2.trancloud.work

# Enable container autostart
pct set 102 -onboot 1

# Verify
pct config 102 | grep onboot
```

## Verification Checklist

- [ ] Container created and running
- [ ] PostgreSQL installed and running
- [ ] Database `openemr_dev` created
- [ ] User `openemr_dev` created with correct privileges
- [ ] Remote connections allowed from 192.168.10.0/24
- [ ] Connection test from k3s master successful
- [ ] Autostart enabled

## Connection Details

Use these values in the Kubernetes secrets:

```yaml
db_host: "192.168.10.30"
db_port: "5432"
db_name: "openemr_dev"
db_user: "openemr_dev"
db_password: "<DB_PASSWORD_FROM_INFISICAL>"
```

## Troubleshooting

### Cannot Connect Remotely

```bash
# Check if PostgreSQL is listening on all interfaces
pct enter 102
netstat -an | grep 5432

# Should show: 0.0.0.0:5432

# Check firewall (should not have one by default in LXC)
iptables -L
```

### Authentication Failed

```bash
# Verify pg_hba.conf has correct entries
cat /etc/postgresql/15/main/pg_hba.conf

# Check PostgreSQL logs
tail -f /var/log/postgresql/postgresql-15-main.log
```

### Container Won't Start

```bash
# Check container status on pve2
pct status 102

# Check logs
pct enter 102
journalctl -xe
```

## Security Notes

- Change default password `<DB_PASSWORD_FROM_INFISICAL>` in production
- Consider setting up SSL/TLS for PostgreSQL connections
- Restrict pg_hba.conf to only necessary IP addresses
- Regular backups using `pg_dump` or Proxmox backup

## Backup Command

```bash
# On openemr-db container
pg_dump -U openemr_dev openemr_dev > /tmp/openemr_dev_backup_$(date +%Y%m%d).sql
```
