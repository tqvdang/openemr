# OpenEMR Deployment Status

**Date**: 2026-01-01
**Status**: 🟡 **PARTIALLY DEPLOYED - WAITING FOR MARIADB**

## Current Status Summary

### ✅ Completed Tasks

1. **Kubernetes Deployment** - **DONE**
   - Namespace `openemr-dev` created
   - Deployment, Services, PVC all deployed
   - Pod running: `openemr-5cf49f9cbf-65vvj`
   - Current pod status: Running (building application)
   ```bash
   kubectl get pods -n openemr-dev
   NAME                       READY   STATUS    RESTARTS      AGE
   openemr-5cf49f9cbf-65vvj   0/1     Running   1 (5m ago)   8m
   ```

2. **pfSense XML Configuration Files** - **DONE**
   - Generated XML snippets for manual pfSense configuration
   - Files location: `infrastructure/homelab/docs/pfsense-xml/`
   - Ready for manual import or SSH configuration

3. **Automation Scripts Created** - **DONE**
   - `create-mariadb-lxc.sh` - MariaDB LXC automation
   - `configure-pfsense-haproxy.sh` - pfSense HAProxy automation
   - `validate-deployment.sh` - Comprehensive validation
   - `create-mariadb-lxc-manual.sh` - Manual MariaDB setup guide

### 🔴 Blocking Issues

**BLOCKER #1: MariaDB LXC Not Created**
- MariaDB server at `192.168.10.30:3306` not accessible
- OpenEMR pod is building but will fail when it tries to connect to database
- Reason: Automation requires `sshpass` which is not installed
- Status: `nc -zv 192.168.10.30 3306` returns "No route to host"

**BLOCKER #2: pfSense HAProxy Not Configured**
- Domain `openemr-dev.trancloud.work` not configured
- HAProxy backend not set up
- Reason: All automation methods require either `sshpass` or manual web UI configuration
- XML files generated and ready for manual configuration

### 🟡 Pending Tasks

1. **Create MariaDB LXC** - **REQUIRED TO PROCEED**
   - Manual steps available in: `create-mariadb-lxc-manual.sh`
   - See "Required Manual Steps" section below

2. **Configure pfSense HAProxy** - **REQUIRED FOR PUBLIC ACCESS**
   - Manual steps available in: `configure-pfsense-haproxy.sh`
   - XML files available in: `docs/pfsense-xml/`

3. **Run Deployment Validation**
   - Script ready: `validate-deployment.sh`
   - Will run after MariaDB and pfSense are configured

## Current Pod Status

The OpenEMR pod is **running** but not **ready** because:

1. **Current Phase**: Building application
   - Running `npm install` to install Node.js dependencies
   - Running `gulp -i` to build assets (SCSS, JS)
   - This is normal for the `openemr/openemr:flex` image on first startup

2. **Next Phase** (once build completes): Database connection
   - Will attempt to connect to MariaDB at `192.168.10.30:3306`
   - **Will fail** because MariaDB LXC doesn't exist yet
   - Pod will crash and restart until database is available

3. **Final Phase** (once database is available): Ready
   - Apache web server will start on port 80/443
   - Readiness probe will pass
   - Pod status will show `1/1 Ready`

## Required Manual Steps

### Step 1: Install sshpass (RECOMMENDED)

This enables automation scripts to run:

```bash
sudo apt update && sudo apt install -y sshpass
```

**After installing sshpass, you can run**:
```bash
cd /home/dang/dev/openemr/infrastructure/homelab/scripts
./create-mariadb-lxc.sh
./configure-pfsense-haproxy.sh ssh
./validate-deployment.sh
```

### Step 2: Create MariaDB LXC (MANUAL ALTERNATIVE)

If you cannot install sshpass, follow these manual steps:

```bash
# Open the manual guide
cat /home/dang/dev/openemr/infrastructure/homelab/scripts/create-mariadb-lxc-manual.sh

# OR execute it to see formatted instructions
./create-mariadb-lxc-manual.sh
```

**Quick summary of manual steps**:

1. SSH to pve2:
   ```bash
   ssh root@pve2.trancloud.work
   # Password: <PASSWORD_FROM_INFISICAL>
   ```

2. Create LXC container:
   ```bash
   pct create 102 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
       --hostname openemr-db \
       --password '<PASSWORD_FROM_INFISICAL>' \
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
   ```

3. Start container:
   ```bash
   pct start 102
   sleep 5
   ```

4. Enter container and install MariaDB:
   ```bash
   pct exec 102 -- bash

   # Inside container:
   apt update && apt install -y mariadb-server mariadb-client vim curl net-tools

   # Secure MariaDB and set root password
   mysql -u root <<'MYSQL'
   ALTER USER 'root'@'localhost' IDENTIFIED BY '<PASSWORD_FROM_INFISICAL>';
   DELETE FROM mysql.user WHERE User='';
   DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
   DROP DATABASE IF EXISTS test;
   DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
   FLUSH PRIVILEGES;
   MYSQL

   # Create OpenEMR database and user
   mysql -u root -p'<PASSWORD_FROM_INFISICAL>' <<'MYSQL'
   CREATE DATABASE openemr_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
   CREATE USER 'openemr_dev'@'%' IDENTIFIED BY '<DB_PASSWORD_FROM_INFISICAL>';
   GRANT ALL PRIVILEGES ON openemr_dev.* TO 'openemr_dev'@'%';
   FLUSH PRIVILEGES;
   SHOW DATABASES;
   SELECT User, Host FROM mysql.user WHERE User='openemr_dev';
   MYSQL

   # Configure for remote connections
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

   # Restart MariaDB
   systemctl restart mariadb
   systemctl status mariadb
   netstat -tlnp | grep 3306
   exit
   ```

5. Test connection from your machine:
   ```bash
   mysql -h 192.168.10.30 -u openemr_dev -p<DB_PASSWORD_FROM_INFISICAL> openemr_dev -e "SELECT 1;"
   ```

### Step 3: Configure pfSense HAProxy (MANUAL)

Option A: Use generated XML files in `docs/pfsense-xml/`
Option B: Use pfSense web UI to manually configure
Option C: SSH to pfSense and edit `/cf/conf/config.xml` directly

See: `docs/pfsense-haproxy-config.md` for detailed steps

### Step 4: Validate Deployment

Once MariaDB and pfSense are configured:

```bash
cd /home/dang/dev/openemr/infrastructure/homelab/scripts
./validate-deployment.sh --verbose
```

## Monitoring Progress

### Watch pod status:
```bash
watch kubectl get pods -n openemr-dev
```

### Watch pod logs (building phase):
```bash
kubectl logs -n openemr-dev -l app=openemr -f
```

### Test MariaDB connectivity:
```bash
nc -zv 192.168.10.30 3306
# Should show: "Connection to 192.168.10.30 3306 port [tcp/mysql] succeeded!"
```

### Test DNS resolution (after pfSense config):
```bash
nslookup openemr-dev.trancloud.work
# Should return: 192.168.10.1
```

### Test HAProxy routing (after pfSense config):
```bash
curl -I https://openemr-dev.trancloud.work
# Should return: HTTP 200 or 302
```

## What Happens Next

**Scenario 1: After MariaDB is created**
1. OpenEMR pod will detect database availability
2. Will run database initialization
3. Apache web server will start
4. Pod will become Ready (1/1)
5. NodePort will be accessible at `http://192.168.10.60:30090`

**Scenario 2: After pfSense is configured**
1. DNS will resolve `openemr-dev.trancloud.work` to pfSense
2. HAProxy will route HTTPS traffic to k3s NodePort
3. Public access via `https://openemr-dev.trancloud.work` will work

**Scenario 3: Both complete**
1. Run validation script to verify all components
2. Access OpenEMR web interface
3. Complete initial setup wizard
4. Deploy Vietnamese PT customizations

## Architecture Diagram

```
Internet
    │
    ▼
┌─────────────────┐
│   pfSense       │  192.168.10.1
│   HAProxy       │  ⚠️ NOT YET CONFIGURED
│   DNS + SSL     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  k3s Cluster    │  192.168.10.60-62
│                 │
│  ┌───────────┐  │
│  │ OpenEMR   │  │  ✅ DEPLOYED
│  │ Pod       │  │  🟡 BUILDING
│  │ NodePort  │  │  Port 30090
│  │ 30090     │  │
│  └─────┬─────┘  │
└────────┼────────┘
         │
         ▼
┌─────────────────┐
│  MariaDB LXC    │  192.168.10.30:3306
│  CT 102         │  ⚠️ NOT YET CREATED
│  Database       │  (BLOCKING)
└─────────────────┘
```

## Decision Point

**Choose one of the following:**

### Option A: Install sshpass and run automation (RECOMMENDED)
```bash
sudo apt install sshpass
cd /home/dang/dev/openemr/infrastructure/homelab/scripts
./create-mariadb-lxc.sh
./configure-pfsense-haproxy.sh ssh
./validate-deployment.sh
```
**Time**: ~5 minutes
**Difficulty**: Easy

### Option B: Manual MariaDB creation + pfSense configuration
```bash
# Follow steps in "Required Manual Steps" section above
# Or execute:
./create-mariadb-lxc-manual.sh  # Shows formatted instructions
```
**Time**: ~20 minutes
**Difficulty**: Medium

### Option C: Wait for assistance
- Provide sudo password to install sshpass
- Or execute manual steps yourself

## Summary

**What's Working:**
- ✅ Kubernetes manifests created and deployed
- ✅ OpenEMR pod running and building
- ✅ pfSense XML files generated
- ✅ All automation scripts created
- ✅ Documentation complete

**What's Blocking:**
- 🔴 MariaDB LXC not created (requires sshpass or manual steps)
- 🔴 pfSense HAProxy not configured (requires sshpass or manual steps)

**Next Action Required:**
- Install sshpass OR execute manual MariaDB setup steps
- Then OpenEMR will automatically complete initialization

---

**Generated**: 2026-01-01
**Last Updated**: Pod status checked at runtime
