#!/bin/bash
# Manual MariaDB LXC Creation Script (without sshpass)
# This script provides the commands to run manually

cat << 'EOF'
================================================================================
MariaDB LXC Creation - Manual Steps
================================================================================

Since sshpass is not installed, please run these commands manually:

1. SSH to pve2:
   ssh root@pve2.trancloud.work
   Password: ${INFRA_PASSWORD}

2. Create the LXC container:
   pct create 102 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
       --hostname openemr-db \
       --password ${INFRA_PASSWORD} \
       --unprivileged 1 \
       --storage local-lvm \
       --rootfs local-lvm:20 \
       --cores 2 \
       --memory 2048 \
       --swap 512 \
       --net0 name=eth0,bridge=vmbr0,ip=192.168.10.30/24,gw=192.168.10.1 \
       --nameserver 192.168.10.1 \
       --searchdomain trancloud.work \
       --onboot 1

3. Start the container:
   pct start 102

4. Wait 5 seconds, then enter the container:
   sleep 5
   pct exec 102 -- bash

5. Inside the container, run these commands:

   # Update system
   apt update && apt upgrade -y

   # Install MariaDB
   apt install -y mariadb-server mariadb-client vim curl net-tools

   # Secure MariaDB and set root password
   mysql -u root <<MYSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${INFRA_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
MYSQL

   # Create OpenEMR database and user
   mysql -u root -p'${INFRA_PASSWORD}' <<MYSQL
CREATE DATABASE openemr_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'openemr_dev'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON openemr_dev.* TO 'openemr_dev'@'%';
FLUSH PRIVILEGES;
SHOW DATABASES;
SELECT User, Host FROM mysql.user WHERE User='openemr_dev';
MYSQL

   # Configure MariaDB for remote connections
   cat > /etc/mysql/mariadb.conf.d/99-openemr.cnf <<MARIADB
[mysqld]
bind-address = 0.0.0.0
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
max_connections = 200
max_allowed_packet = 64M
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
innodb_flush_log_at_trx_commit = 2
query_cache_type = 1
query_cache_size = 128M
tmp_table_size = 128M
max_heap_table_size = 128M
MARIADB

   # Restart MariaDB
   systemctl restart mariadb

   # Verify MariaDB is running
   systemctl status mariadb

   # Check if listening on all interfaces
   netstat -tlnp | grep 3306

   # Exit the container
   exit

6. Test connection from your machine:
   mysql -h 192.168.10.30 -u openemr_dev -p${DB_PASSWORD} openemr_dev -e "SELECT 1;"

   Expected output: Should show "1"

================================================================================
Quick Copy-Paste Version (run these in sequence):
================================================================================

# Step 1: SSH to pve2
ssh root@pve2.trancloud.work

# Step 2-3: Create and start container
pct create 102 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst --hostname openemr-db --password '${INFRA_PASSWORD}' --unprivileged 1 --storage local-lvm --rootfs local-lvm:20 --cores 2 --memory 2048 --swap 512 --net0 name=eth0,bridge=vmbr0,ip=192.168.10.30/24,gw=192.168.10.1 --nameserver 192.168.10.1 --searchdomain trancloud.work --onboot 1 && pct start 102 && sleep 5

# Step 4: Enter container
pct exec 102 -- bash

# Step 5a: Install MariaDB
apt update && apt install -y mariadb-server mariadb-client vim curl net-tools

# Step 5b: Secure MariaDB
mysql -u root <<'MYSQL'
ALTER USER 'root'@'localhost' IDENTIFIED BY '${INFRA_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
MYSQL

# Step 5c: Create database and user
mysql -u root -p'${INFRA_PASSWORD}' <<'MYSQL'
CREATE DATABASE openemr_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'openemr_dev'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON openemr_dev.* TO 'openemr_dev'@'%';
FLUSH PRIVILEGES;
SHOW DATABASES;
SELECT User, Host FROM mysql.user WHERE User='openemr_dev';
MYSQL

# Step 5d: Configure remote access
cat > /etc/mysql/mariadb.conf.d/99-openemr.cnf <<'MARIADB'
[mysqld]
bind-address = 0.0.0.0
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
max_connections = 200
max_allowed_packet = 64M
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
MARIADB

# Step 5e: Restart and verify
systemctl restart mariadb && systemctl status mariadb && netstat -tlnp | grep 3306

# Step 5f: Exit container
exit

================================================================================
After completion, OpenEMR pod will automatically connect to the database.
Check with: kubectl get pods -n openemr-dev
================================================================================
EOF
