#!/bin/bash
# Automated MariaDB LXC Creation with embedded password
# This script will SSH to pve2 and create the MariaDB LXC

set -e

PVE_HOST="pve2.trancloud.work"
PVE_USER="root"
PVE_PASS="${INFRA_PASSWORD}"
LXC_ID="102"
LXC_IP="192.168.10.30"
DB_ROOT_PASS="${INFRA_PASSWORD}"
DB_NAME="openemr_dev"
DB_USER="openemr_dev"
DB_PASS="${DB_PASSWORD}"

echo "================================================"
echo "Creating MariaDB LXC on $PVE_HOST"
echo "================================================"

# Create a temporary expect script
cat > /tmp/create-mariadb.exp <<'EXPECT_SCRIPT'
#!/usr/bin/expect -f

set timeout 300
set pve_host [lindex $argv 0]
set pve_user [lindex $argv 1]
set pve_pass [lindex $argv 2]

# SSH to pve2
spawn ssh -o StrictHostKeyChecking=no ${pve_user}@${pve_host}

expect {
    "password:" {
        send "${pve_pass}\r"
        exp_continue
    }
    "# " {
        # We're in! Now create the LXC
        send "pct create 102 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst --hostname openemr-db --password '${INFRA_PASSWORD}' --unprivileged 1 --storage local-lvm --rootfs local-lvm:20 --cores 2 --memory 2048 --swap 512 --net0 name=eth0,bridge=vmbr0,ip=192.168.10.30/24,gw=192.168.10.1 --nameserver 192.168.10.1 --searchdomain trancloud.work --onboot 1\r"

        expect "# "
        send "pct start 102\r"

        expect "# "
        send "sleep 5\r"

        expect "# "
        send "pct exec 102 -- bash -c 'apt update && apt install -y mariadb-server mariadb-client vim curl net-tools'\r"

        expect "# " {send "echo 'MariaDB installed'\r"}

        expect "# "
        send "pct exec 102 -- bash -c \"mysql -u root <<'MYSQL'\nALTER USER 'root'@'localhost' IDENTIFIED BY '${INFRA_PASSWORD}';\nDELETE FROM mysql.user WHERE User='';\nDELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');\nDROP DATABASE IF EXISTS test;\nDELETE FROM mysql.db WHERE Db='test' OR Db='test\\\\\\\\_%';\nFLUSH PRIVILEGES;\nMYSQL\"\r"

        expect "# "
        send "pct exec 102 -- bash -c \"mysql -u root -p'${INFRA_PASSWORD}' <<'MYSQL'\nCREATE DATABASE openemr_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;\nCREATE USER 'openemr_dev'@'%' IDENTIFIED BY '${DB_PASSWORD}';\nGRANT ALL PRIVILEGES ON openemr_dev.* TO 'openemr_dev'@'%';\nFLUSH PRIVILEGES;\nSHOW DATABASES;\nSELECT User, Host FROM mysql.user WHERE User='openemr_dev';\nMYSQL\"\r"

        expect "# "
        send "pct exec 102 -- bash -c \"cat > /etc/mysql/mariadb.conf.d/99-openemr.cnf <<'MARIADB'\n\[mysqld\]\nbind-address = 0.0.0.0\ncharacter-set-server = utf8mb4\ncollation-server = utf8mb4_general_ci\nmax_connections = 200\nmax_allowed_packet = 64M\ninnodb_buffer_pool_size = 512M\ninnodb_log_file_size = 128M\nMARIADB\"\r"

        expect "# "
        send "pct exec 102 -- systemctl restart mariadb\r"

        expect "# "
        send "pct exec 102 -- systemctl status mariadb\r"

        expect "# "
        send "pct exec 102 -- bash -c 'netstat -tlnp | grep 3306'\r"

        expect "# "
        send "exit\r"
    }
}

expect eof
EXPECT_SCRIPT

# Check if expect is installed
if ! command -v expect &> /dev/null; then
    echo "ERROR: expect is not installed"
    echo "Please install it with: sudo apt install expect"
    echo ""
    echo "OR use the manual steps in: create-mariadb-lxc-manual.sh"
    rm -f /tmp/create-mariadb.exp
    exit 1
fi

# Make expect script executable
chmod +x /tmp/create-mariadb.exp

# Run the expect script
echo "Running automated installation..."
/tmp/create-mariadb.exp "$PVE_HOST" "$PVE_USER" "$PVE_PASS"

# Cleanup
rm -f /tmp/create-mariadb.exp

echo ""
echo "================================================"
echo "Testing connection to MariaDB..."
echo "================================================"

sleep 3

if command -v mysql &> /dev/null; then
    mysql -h $LXC_IP -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT 1 AS test;" 2>/dev/null && echo "✅ MariaDB connection successful!" || echo "⚠️  MariaDB connection failed - may need more time to start"
else
    echo "mysql client not installed - testing with nc..."
    nc -zv $LXC_IP 3306 && echo "✅ Port 3306 is accessible!" || echo "⚠️  Port 3306 not yet accessible"
fi

echo ""
echo "================================================"
echo "MariaDB LXC Creation Complete!"
echo "================================================"
echo "Container ID: $LXC_ID"
echo "IP Address: $LXC_IP"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Password: $DB_PASS"
echo ""
echo "Next: Check OpenEMR pod status with:"
echo "  kubectl get pods -n openemr-dev"
