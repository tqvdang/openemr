# OpenEMR Deployment Checklist

Use this checklist to track your deployment progress.

## Pre-Deployment

- [ ] Review deployment architecture in `DEPLOYMENT_GUIDE.md`
- [ ] Ensure pve2 access: https://pve2.trancloud.work (root / <PASSWORD_FROM_INFISICAL>)
- [ ] Ensure pfSense access: https://pfsense.trancloud.work (dang / <PASSWORD_FROM_INFISICAL>)
- [ ] Verify k3s cluster is running: `kubectl get nodes`
- [ ] Review all configuration files

## Phase 1: Database Setup (Estimated: 15-20 minutes)

### 1.1 Create MariaDB LXC Container

- [ ] Login to pve2 web UI: https://pve2.trancloud.work
- [ ] Click "Create CT" button
- [ ] Configure container (CT ID: 102, IP: 192.168.10.30)
  - [ ] Hostname: openemr-db
  - [ ] Template: debian-12-standard
  - [ ] Disk: 20GB
  - [ ] CPU: 2 cores
  - [ ] Memory: 2048MB
  - [ ] Network: 192.168.10.30/24, Gateway: 192.168.10.1
- [ ] Start container
- [ ] Enter container: `pct enter 102`

### 1.2 Install and Configure MariaDB

- [ ] Update system: `apt update && apt upgrade -y`
- [ ] Install MariaDB: `apt install -y mariadb-server mariadb-client`
- [ ] Run secure installation: `mysql_secure_installation`
  - [ ] Set root password: <PASSWORD_FROM_INFISICAL>
- [ ] Create database and user:
  ```bash
  mysql -u root -p
  CREATE DATABASE openemr_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  CREATE USER 'openemr_dev'@'%' IDENTIFIED BY '<DB_PASSWORD_FROM_INFISICAL>';
  GRANT ALL PRIVILEGES ON openemr_dev.* TO 'openemr_dev'@'%';
  FLUSH PRIVILEGES;
  EXIT;
  ```
- [ ] Edit `/etc/mysql/mariadb.conf.d/50-server.cnf`:
  - [ ] Change `bind-address` to `0.0.0.0`
- [ ] Restart MariaDB: `systemctl restart mariadb`
- [ ] Enable autostart: `pct set 102 -onboot 1` (from pve2 host)

### 1.3 Test Database Connection

- [ ] From k3s master or your workstation:
  ```bash
  mysql -h 192.168.10.30 -u openemr_dev -p openemr_dev
  # Password: <DB_PASSWORD_FROM_INFISICAL>
  ```
- [ ] Should connect successfully ✓

**Detailed Guide**: `docs/mariadb-lxc-setup.md`

## Phase 2: Kubernetes Deployment (Estimated: 10 minutes)

### 2.1 Deploy to k3s

- [ ] Navigate to project: `cd /home/dang/dev/openemr`
- [ ] Run deployment script:
  ```bash
  ./infrastructure/homelab/scripts/deploy-dev.sh
  ```
  **OR manual deployment**:
  ```bash
  kubectl apply -f infrastructure/homelab/k8s/namespaces/openemr-dev.yaml
  kubectl apply -k infrastructure/homelab/k8s/overlays/dev/
  ```

### 2.2 Verify Deployment

- [ ] Check pods: `kubectl get pods -n openemr-dev`
- [ ] Pod status should be "Running" ✓
- [ ] Check logs: `kubectl logs -n openemr-dev -l app=openemr -f`
- [ ] No errors in logs ✓
- [ ] Test NodePort: `curl http://192.168.10.60:30090`
- [ ] Should return HTML or redirect ✓

**Detailed Guide**: `k8s/README.md`

## Phase 3: pfSense HAProxy Configuration (Estimated: 10 minutes)

### 3.1 Configure DNS Override

- [ ] Login to pfSense: https://pfsense.trancloud.work (dang / <PASSWORD_FROM_INFISICAL>)
- [ ] Navigate to: Services → DNS Resolver → Host Overrides
- [ ] Click "Add" and configure:
  - [ ] Host: openemr-dev
  - [ ] Domain: trancloud.work
  - [ ] IP: 192.168.10.1
- [ ] Click "Save" and "Apply Changes"
- [ ] Test: `nslookup openemr-dev.trancloud.work` → should return 192.168.10.1 ✓

### 3.2 Create HAProxy Backend

- [ ] Navigate to: Services → HAProxy → Backend
- [ ] Click "Add" and configure:
  - [ ] Name: openemr-dev-be
  - [ ] Mode: HTTP
  - [ ] Server: k3s-openemr, 192.168.10.60:30090
  - [ ] Health check: HTTP GET /
- [ ] Click "Save" and "Apply Changes"

### 3.3 Configure Frontend ACL and Action

- [ ] Navigate to: Services → HAProxy → Frontend
- [ ] Edit "trancloud-https" frontend
- [ ] Add ACL in "Access Control lists" section:
  - [ ] Name: openemr-dev-acl
  - [ ] Expression: Host matches:
  - [ ] Value: openemr-dev.trancloud.work
- [ ] Add Action in "Actions" section:
  - [ ] Action: Use Backend
  - [ ] Condition: openemr-dev-acl
  - [ ] Backend: openemr-dev-be
- [ ] Click "Save" and "Apply Changes"

### 3.4 Verify HAProxy

- [ ] Navigate to: Services → HAProxy → Stats
- [ ] Click "View HAProxy Stats"
- [ ] Check openemr-dev-be status: should be GREEN ✓

**Detailed Guide**: `docs/pfsense-haproxy-config.md`

## Phase 4: Testing (Estimated: 5 minutes)

### 4.1 Internal Testing

- [ ] Test DNS: `nslookup openemr-dev.trancloud.work` → 192.168.10.1 ✓
- [ ] Test HTTPS: `curl -I https://openemr-dev.trancloud.work` → HTTP 200 ✓
- [ ] Test direct NodePort: `curl http://192.168.10.60:30090` → HTML ✓

### 4.2 Browser Testing

- [ ] Open browser: https://openemr-dev.trancloud.work
- [ ] OpenEMR page loads ✓
- [ ] SSL certificate valid (*.trancloud.work) ✓
- [ ] No browser warnings ✓

### 4.3 Application Testing

- [ ] Complete OpenEMR initial setup (if first time)
- [ ] Login with admin credentials
- [ ] Verify database connection working
- [ ] Check OpenEMR dashboard loads
- [ ] Test basic functionality

## Phase 5: Optional - Public Access

### Option A: Cloudflare DNS Proxy (Recommended)

- [ ] Login to Cloudflare dashboard
- [ ] Add A record:
  - [ ] Name: openemr-dev
  - [ ] IPv4: Your public IP
  - [ ] Proxy: Enabled (orange cloud)
- [ ] Set SSL/TLS mode to "Full (strict)"
- [ ] Test from external network

### Option B: Direct Port Forward

- [ ] pfSense → Firewall → NAT → Port Forward
- [ ] Add rule: WAN:443 → 192.168.10.1:443
- [ ] Update external DNS
- [ ] Test from external network

## Post-Deployment

- [ ] Document credentials in password manager
- [ ] Set up regular database backups
- [ ] Configure OpenEMR settings
- [ ] Set up monitoring/alerting
- [ ] Create staging/production environments (future)

## Rollback Plan (If Needed)

If deployment fails, rollback with:

```bash
# Delete k8s deployment
kubectl delete namespace openemr-dev

# Stop and remove LXC
pct stop 102
pct destroy 102

# Remove HAProxy config
# - Delete backend: openemr-dev-be
# - Remove ACL: openemr-dev-acl
# - Remove DNS override

# Remove DNS override in pfSense
```

## Deployment Summary

Once all checkboxes are complete:

- ✅ MariaDB LXC created and running at 192.168.10.30
- ✅ OpenEMR deployed to k3s namespace: openemr-dev
- ✅ HAProxy configured for public access
- ✅ DNS configured: openemr-dev.trancloud.work
- ✅ Internal access: http://192.168.10.60:30090
- ✅ Public access: https://openemr-dev.trancloud.work
- ✅ Application tested and working

## Support Resources

- Main Guide: `DEPLOYMENT_GUIDE.md`
- MariaDB Setup: `docs/mariadb-lxc-setup.md`
- HAProxy Config: `docs/pfsense-haproxy-config.md`
- Kubernetes: `k8s/README.md`
- Homelab Process: `.local/homelab-app-onboarding.md`

## Estimated Total Time

- Phase 1 (Database): 15-20 minutes
- Phase 2 (K8s Deploy): 10 minutes
- Phase 3 (HAProxy): 10 minutes
- Phase 4 (Testing): 5 minutes
- **Total**: ~40-45 minutes

Good luck with your deployment! 🚀
