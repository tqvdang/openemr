#!/bin/bash
#===============================================================================
# Script: create-mariadb-lxc.sh
# Description: Automated creation of MariaDB LXC container on Proxmox VE
# Target: pve2.trancloud.work
#
# This script uses the Proxmox API (via pvesh) to:
#   1. Create an LXC container with specified configuration
#   2. Start the container
#   3. Install and configure MariaDB
#   4. Create the openemr_dev database and user
#   5. Configure remote access
#
# Usage: ./create-mariadb-lxc.sh [--dry-run] [--skip-db-setup]
#
# Options:
#   --dry-run       Show commands without executing
#   --skip-db-setup Skip MariaDB installation and configuration
#   --force         Delete existing container if present
#
# Author: AI-Generated with Claude Code
# Date: 2026-01-01
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration - Container Specifications
#-------------------------------------------------------------------------------
PVE_HOST="192.168.10.12"
PVE_USER="root@pam"
PVE_PASSWORD="${INFRA_PASSWORD}"

# Container configuration
CT_ID="102"
CT_HOSTNAME="openemr-db"
CT_PASSWORD="${INFRA_PASSWORD}"
CT_TEMPLATE="debian-12-standard_12.12-1_amd64.tar.zst"
CT_STORAGE="local-lvm"
CT_DISK_SIZE="20"
CT_CORES="2"
CT_MEMORY="2048"
CT_SWAP="512"
CT_IP="192.168.10.30"
CT_NETMASK="24"
CT_GATEWAY="192.168.10.1"
CT_BRIDGE="vmbr0"
CT_DNS_DOMAIN="trancloud.work"
CT_DNS_SERVER="192.168.10.1"

# Database configuration
DB_NAME="openemr_dev"
DB_USER="openemr_dev"
DB_PASSWORD="${DB_PASSWORD}"
DB_ROOT_PASSWORD="${INFRA_PASSWORD}"

#-------------------------------------------------------------------------------
# Colors for output
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${GREEN}==>${NC} ${BLUE}$1${NC}"
    echo "----------------------------------------"
}

# Check if running in dry-run mode
DRY_RUN=false
SKIP_DB_SETUP=false
FORCE=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            log_warn "Running in DRY-RUN mode - no changes will be made"
            ;;
        --skip-db-setup)
            SKIP_DB_SETUP=true
            log_warn "Skipping MariaDB installation and configuration"
            ;;
        --force)
            FORCE=true
            log_warn "Force mode enabled - will delete existing container"
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--skip-db-setup] [--force]"
            echo ""
            echo "Options:"
            echo "  --dry-run       Show commands without executing"
            echo "  --skip-db-setup Skip MariaDB installation and configuration"
            echo "  --force         Delete existing container if present"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
    esac
done

# Execute command (respects dry-run mode)
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would execute: $*"
        return 0
    else
        "$@"
    fi
}

# Execute SSH command on Proxmox host
ssh_pve() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would execute on PVE: $*"
        return 0
    else
        sshpass -p "${PVE_PASSWORD}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            "root@${PVE_HOST}" "$@"
    fi
}

# Execute command inside container via pct exec
pct_exec() {
    local cmd="$1"
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would execute in container: $cmd"
        return 0
    else
        sshpass -p "${PVE_PASSWORD}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            "root@${PVE_HOST}" "pct exec ${CT_ID} -- bash -c '$cmd'"
    fi
}

#-------------------------------------------------------------------------------
# Pre-flight Checks
#-------------------------------------------------------------------------------
log_step "Pre-flight Checks"

# Check for required tools
if ! command -v sshpass &> /dev/null; then
    log_error "sshpass is required but not installed"
    log_info "Install with: sudo apt install sshpass"
    exit 1
fi
log_success "sshpass is available"

# Test SSH connectivity to Proxmox host
log_info "Testing SSH connectivity to ${PVE_HOST}..."
if sshpass -p "${PVE_PASSWORD}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=10 "root@${PVE_HOST}" "echo 'SSH connection successful'" 2>/dev/null; then
    log_success "SSH connection to ${PVE_HOST} successful"
else
    log_error "Cannot connect to ${PVE_HOST} via SSH"
    log_info "Make sure the host is reachable and credentials are correct"
    exit 1
fi

# Check if container already exists
log_info "Checking if container ${CT_ID} already exists..."
if ssh_pve "pct status ${CT_ID}" 2>/dev/null; then
    if [ "$FORCE" = true ]; then
        log_warn "Container ${CT_ID} exists - will be deleted (--force enabled)"
    else
        log_error "Container ${CT_ID} already exists!"
        log_info "Use --force to delete and recreate, or choose a different CT ID"
        exit 1
    fi
else
    log_success "Container ${CT_ID} does not exist - ready to create"
fi

#-------------------------------------------------------------------------------
# Step 1: Download Template (if needed)
#-------------------------------------------------------------------------------
log_step "Step 1: Checking/Downloading Debian 12 Template"

TEMPLATE_PATH="/var/lib/vz/template/cache/${CT_TEMPLATE}"

log_info "Checking for template: ${CT_TEMPLATE}"
if ssh_pve "test -f ${TEMPLATE_PATH}"; then
    log_success "Template already exists"
else
    log_info "Downloading Debian 12 template..."
    if [ "$DRY_RUN" = false ]; then
        ssh_pve "pveam update"
        ssh_pve "pveam download local ${CT_TEMPLATE}"
    else
        log_info "[DRY-RUN] Would download template: ${CT_TEMPLATE}"
    fi
    log_success "Template downloaded"
fi

#-------------------------------------------------------------------------------
# Step 2: Delete Existing Container (if --force)
#-------------------------------------------------------------------------------
if [ "$FORCE" = true ]; then
    log_step "Step 2: Removing Existing Container"

    # Stop container if running
    log_info "Stopping container ${CT_ID} if running..."
    ssh_pve "pct stop ${CT_ID} 2>/dev/null || true"
    sleep 2

    # Destroy container
    log_info "Destroying container ${CT_ID}..."
    ssh_pve "pct destroy ${CT_ID} --purge 2>/dev/null || true"
    log_success "Existing container removed"
fi

#-------------------------------------------------------------------------------
# Step 3: Create LXC Container
#-------------------------------------------------------------------------------
log_step "Step 3: Creating LXC Container"

log_info "Creating container with the following specifications:"
echo "  - CT ID: ${CT_ID}"
echo "  - Hostname: ${CT_HOSTNAME}"
echo "  - Template: ${CT_TEMPLATE}"
echo "  - Storage: ${CT_STORAGE}"
echo "  - Disk Size: ${CT_DISK_SIZE}GB"
echo "  - CPU Cores: ${CT_CORES}"
echo "  - Memory: ${CT_MEMORY}MB"
echo "  - Swap: ${CT_SWAP}MB"
echo "  - Network: ${CT_IP}/${CT_NETMASK} via ${CT_BRIDGE}"
echo "  - Gateway: ${CT_GATEWAY}"
echo "  - DNS: ${CT_DNS_SERVER}"

# Build pct create command
CREATE_CMD="pct create ${CT_ID} local:vztmpl/${CT_TEMPLATE} \
    --hostname ${CT_HOSTNAME} \
    --password '${CT_PASSWORD}' \
    --unprivileged 1 \
    --storage ${CT_STORAGE} \
    --rootfs ${CT_STORAGE}:${CT_DISK_SIZE} \
    --cores ${CT_CORES} \
    --memory ${CT_MEMORY} \
    --swap ${CT_SWAP} \
    --net0 name=eth0,bridge=${CT_BRIDGE},ip=${CT_IP}/${CT_NETMASK},gw=${CT_GATEWAY} \
    --nameserver ${CT_DNS_SERVER} \
    --searchdomain ${CT_DNS_DOMAIN} \
    --onboot 1 \
    --start 0"

if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would execute:"
    echo "${CREATE_CMD}"
else
    log_info "Executing pct create..."
    ssh_pve "${CREATE_CMD}"
fi

log_success "Container created successfully"

#-------------------------------------------------------------------------------
# Step 4: Start Container
#-------------------------------------------------------------------------------
log_step "Step 4: Starting Container"

log_info "Starting container ${CT_ID}..."
ssh_pve "pct start ${CT_ID}"

# Wait for container to be fully running
log_info "Waiting for container to start..."
if [ "$DRY_RUN" = false ]; then
    sleep 5

    # Wait for network to be ready
    for i in {1..30}; do
        if ssh_pve "pct exec ${CT_ID} -- ping -c 1 8.8.8.8" &>/dev/null; then
            log_success "Container network is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            log_warn "Network not ready after 30 seconds, continuing anyway..."
        fi
        sleep 1
    done
fi

log_success "Container started"

#-------------------------------------------------------------------------------
# Step 5: Install MariaDB
#-------------------------------------------------------------------------------
if [ "$SKIP_DB_SETUP" = false ]; then
    log_step "Step 5: Installing MariaDB"

    log_info "Updating package lists..."
    pct_exec "apt update"

    log_info "Installing MariaDB server and tools..."
    pct_exec "DEBIAN_FRONTEND=noninteractive apt install -y mariadb-server mariadb-client vim curl net-tools"

    log_success "MariaDB installed"

    #---------------------------------------------------------------------------
    # Step 6: Secure MariaDB Installation
    #---------------------------------------------------------------------------
    log_step "Step 6: Securing MariaDB"

    log_info "Running mysql_secure_installation equivalent..."

    # Set root password and secure installation
    SECURE_MYSQL_CMD="mysql -u root <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\\\_%';

-- Reload privileges
FLUSH PRIVILEGES;
EOF"

    pct_exec "${SECURE_MYSQL_CMD}"
    log_success "MariaDB secured"

    #---------------------------------------------------------------------------
    # Step 7: Create OpenEMR Database and User
    #---------------------------------------------------------------------------
    log_step "Step 7: Creating OpenEMR Database and User"

    log_info "Creating database '${DB_NAME}' and user '${DB_USER}'..."

    CREATE_DB_CMD="mysql -u root -p'${DB_ROOT_PASSWORD}' <<EOF
-- Create database with utf8mb4 character set
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Create user for OpenEMR (allow remote connections)
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';

-- Grant all privileges
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Verify
SHOW DATABASES;
SELECT User, Host FROM mysql.user WHERE User='${DB_USER}';
EOF"

    pct_exec "${CREATE_DB_CMD}"
    log_success "Database and user created"

    #---------------------------------------------------------------------------
    # Step 8: Configure MariaDB for Remote Connections
    #---------------------------------------------------------------------------
    log_step "Step 8: Configuring MariaDB for Remote Access"

    log_info "Updating MariaDB configuration..."

    # Create custom configuration file for OpenEMR
    CONFIG_CMD="cat > /etc/mysql/mariadb.conf.d/99-openemr.cnf <<'EOF'
# OpenEMR MariaDB Configuration
# Generated by create-mariadb-lxc.sh

[mysqld]
# Allow remote connections
bind-address = 0.0.0.0

# Character set for OpenEMR
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci

# Performance tuning
max_connections = 200
max_allowed_packet = 64M
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
innodb_flush_log_at_trx_commit = 2

# Query cache
query_cache_type = 1
query_cache_size = 128M

# Temporary tables
tmp_table_size = 128M
max_heap_table_size = 128M

# Logging (optional - uncomment for debugging)
# slow_query_log = 1
# slow_query_log_file = /var/log/mysql/slow.log
# long_query_time = 2
EOF"

    pct_exec "${CONFIG_CMD}"
    log_success "Configuration file created"

    log_info "Restarting MariaDB service..."
    pct_exec "systemctl restart mariadb"
    sleep 3

    # Verify MariaDB is running
    log_info "Verifying MariaDB status..."
    pct_exec "systemctl status mariadb --no-pager"

    log_success "MariaDB configured for remote access"
fi

#-------------------------------------------------------------------------------
# Step 9: Verification
#-------------------------------------------------------------------------------
log_step "Step 9: Verification"

log_info "Verifying container status..."
ssh_pve "pct status ${CT_ID}"

if [ "$SKIP_DB_SETUP" = false ]; then
    log_info "Verifying MariaDB is listening on all interfaces..."
    pct_exec "netstat -tlnp | grep 3306"

    log_info "Verifying database exists..."
    pct_exec "mysql -u root -p'${DB_ROOT_PASSWORD}' -e 'SHOW DATABASES;'"

    log_info "Verifying user permissions..."
    pct_exec "mysql -u root -p'${DB_ROOT_PASSWORD}' -e \"SHOW GRANTS FOR '${DB_USER}'@'%';\""
fi

log_success "All verifications passed"

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "==============================================================================="
echo -e "${GREEN}MariaDB LXC Container Created Successfully!${NC}"
echo "==============================================================================="
echo ""
echo "Container Information:"
echo "  - Container ID: ${CT_ID}"
echo "  - Hostname: ${CT_HOSTNAME}"
echo "  - IP Address: ${CT_IP}"
echo "  - Gateway: ${CT_GATEWAY}"
echo ""
if [ "$SKIP_DB_SETUP" = false ]; then
echo "Database Connection Details:"
echo "  - Host: ${CT_IP}"
echo "  - Port: 3306"
echo "  - Database: ${DB_NAME}"
echo "  - Username: ${DB_USER}"
echo "  - Password: ${DB_PASSWORD}"
echo "  - Root Password: ${DB_ROOT_PASSWORD}"
echo ""
fi
echo "Access Commands:"
echo "  - SSH to Proxmox:  ssh root@${PVE_HOST}"
echo "  - Enter Container: pct enter ${CT_ID}"
echo "  - MariaDB CLI:     mysql -h ${CT_IP} -u ${DB_USER} -p"
echo ""
echo "Kubernetes Configuration (update in overlays/dev/):"
echo "  db_host: \"${CT_IP}\""
echo "  db_port: \"3306\""
echo "  db_user: \"${DB_USER}\""
echo "  db_password: \"${DB_PASSWORD}\""
echo ""
echo "Next Steps:"
echo "  1. Test connection: mysql -h ${CT_IP} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME}"
echo "  2. Update Kubernetes secrets with database credentials"
echo "  3. Deploy OpenEMR: ./deploy-dev.sh"
echo ""
log_success "Script completed successfully!"
