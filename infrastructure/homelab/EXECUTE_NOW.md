# Execute OpenEMR Deployment NOW

**Status**: Ready to execute
**Estimated Time**: 40-45 minutes

## Prerequisites - Install First

You need to install these dependencies before running the automation scripts:

```bash
# Install required packages
sudo apt update
sudo apt install -y sshpass jq mariadb-client netcat-openbsd dnsutils

# Verify installations
command -v sshpass && echo "✓ sshpass installed"
command -v jq && echo "✓ jq installed"
command -v mysql && echo "✓ mysql installed"
command -v nc && echo "✓ nc installed"
command -v nslookup && echo "✓ nslookup installed"
```

## Execution Steps

### Step 1: Create MariaDB LXC (15-20 minutes)

```bash
cd /home/dang/dev/openemr/infrastructure/homelab/scripts

# Preview what will happen (dry-run)
./create-mariadb-lxc.sh --dry-run

# Execute the creation
./create-mariadb-lxc.sh
```

**What happens:**
- SSHs to pve2.trancloud.work as root
- Creates LXC container CT 102
- IP: 192.168.10.30
- Installs MariaDB
- Creates database `openemr_dev`
- Creates user `openemr_dev` with password `<DB_PASSWORD_FROM_INFISICAL>`
- Configures for remote access

**Verify:**
```bash
# Test database connection
mysql -h 192.168.10.30 -u openemr_dev -p<DB_PASSWORD_FROM_INFISICAL> openemr_dev -e "SELECT 1;"
```

**Expected output**: Should return `1`

---

### Step 2: Deploy to k3s (10 minutes)

```bash
cd /home/dang/dev/openemr/infrastructure/homelab/scripts

# Make sure kubectl is configured
kubectl get nodes

# Execute deployment
./deploy-dev.sh
```

**What happens:**
- Checks MariaDB connectivity
- Creates namespace `openemr-dev`
- Deploys OpenEMR pod
- Creates NodePort service on port 30090
- Creates persistent volume claim
- Waits for pod to be ready

**Verify:**
```bash
# Check pod status
kubectl get pods -n openemr-dev

# Test NodePort
curl -I http://192.168.10.60:30090
```

**Expected output**:
- Pod status: `Running`
- curl: HTTP 200 or 302

---

### Step 3: Configure pfSense HAProxy (10 minutes)

```bash
cd /home/dang/dev/openemr/infrastructure/homelab/scripts

# Execute pfSense configuration via SSH
./configure-pfsense-haproxy.sh ssh
```

**What happens:**
- SSHs to pfsense.trancloud.work as dang
- Adds DNS override: `openemr-dev.trancloud.work` → `192.168.10.1`
- Creates HAProxy backend: `openemr-dev-be` → `192.168.10.60:30090`
- Adds ACL: `openemr-dev-acl` (host matches openemr-dev.trancloud.work)
- Adds action: Use backend `openemr-dev-be`
- Restarts DNS resolver and HAProxy

**Verify:**
```bash
# Test DNS resolution
nslookup openemr-dev.trancloud.work

# Test HTTPS access
curl -I -k https://openemr-dev.trancloud.work
```

**Expected output**:
- DNS: `192.168.10.1`
- curl: HTTP 200 or 302

---

### Step 4: Validate Deployment (5 minutes)

```bash
cd /home/dang/dev/openemr/infrastructure/homelab/scripts

# Run comprehensive validation
./validate-deployment.sh

# Or with verbose output
./validate-deployment.sh --verbose
```

**What happens:**
- Tests all 9 deployment components
- Shows color-coded results
- Provides remediation for failures
- Generates summary report

**Expected output:**
```
✅ MariaDB connectivity: PASS
✅ Database authentication: PASS
✅ k3s cluster accessible: PASS
✅ Nodes ready: PASS
✅ Deployment ready: PASS
✅ Pod running: PASS
✅ NodePort accessible: PASS
✅ DNS resolving: PASS
✅ HAProxy routing: PASS
✅ SSL certificate valid: PASS
✅ Application responding: PASS

All critical tests passed!
```

---

## Alternative: Manual Execution

If automation scripts fail, you can configure manually:

### Option A: Manual MariaDB Setup

Follow: `infrastructure/homelab/docs/mariadb-lxc-setup.md`

### Option B: Manual k8s Deployment

```bash
kubectl apply -f infrastructure/homelab/k8s/namespaces/openemr-dev.yaml
kubectl apply -k infrastructure/homelab/k8s/overlays/dev/
```

### Option C: Manual pfSense Configuration

Follow: `infrastructure/homelab/docs/pfsense-haproxy-config.md`

Or use XML snippets in: `infrastructure/homelab/docs/pfsense-xml/`

---

## Troubleshooting

### Script Fails: "sshpass not found"

```bash
sudo apt install sshpass
```

### Script Fails: "Cannot connect to pve2"

Check SSH connectivity:
```bash
ssh root@pve2.trancloud.work
# Password: <PASSWORD_FROM_INFISICAL>
```

### Script Fails: "Cannot connect to pfSense"

Check SSH connectivity:
```bash
ssh dang@pfsense.trancloud.work
# Password: <PASSWORD_FROM_INFISICAL>
```

### Pod Not Starting

Check logs:
```bash
kubectl logs -n openemr-dev -l app=openemr
kubectl describe pod -n openemr-dev -l app=openemr
```

### 503 Error from HAProxy

Check backend status:
- Login to https://pfsense.trancloud.work
- Navigate to: Services → HAProxy → Stats
- Check if `openemr-dev-be` is green

### DNS Not Resolving

Re-run pfSense configuration:
```bash
./configure-pfsense-haproxy.sh ssh
```

---

## Access After Deployment

Once all steps complete successfully:

### Internal Access (from homelab network)
```
http://192.168.10.60:30090
```

### Public Access (HTTPS with SSL)
```
https://openemr-dev.trancloud.work
```

### Initial OpenEMR Setup

1. Navigate to https://openemr-dev.trancloud.work
2. Complete the setup wizard if this is first time
3. Default credentials (from secrets):
   - Username: `admin`
   - Password: `<ADMIN_PASSWORD_FROM_INFISICAL>`

---

## Quick Command Summary

```bash
# Install prerequisites
sudo apt install -y sshpass jq mariadb-client netcat-openbsd dnsutils

# Navigate to scripts
cd /home/dang/dev/openemr/infrastructure/homelab/scripts

# Execute deployment (in order)
./create-mariadb-lxc.sh          # Step 1: MariaDB LXC
./deploy-dev.sh                   # Step 2: k8s deployment
./configure-pfsense-haproxy.sh ssh # Step 3: pfSense HAProxy
./validate-deployment.sh          # Step 4: Validation

# Access OpenEMR
open https://openemr-dev.trancloud.work
```

---

## Credentials Reference

| Service | Host | User | Password |
|---------|------|------|----------|
| pve2 | pve2.trancloud.work | root | <PASSWORD_FROM_INFISICAL> |
| pfSense | pfsense.trancloud.work | dang | <PASSWORD_FROM_INFISICAL> |
| MariaDB | 192.168.10.30 | openemr_dev | <DB_PASSWORD_FROM_INFISICAL> |
| MariaDB root | 192.168.10.30 | root | <PASSWORD_FROM_INFISICAL> |
| OpenEMR | openemr-dev.trancloud.work | admin | <ADMIN_PASSWORD_FROM_INFISICAL> |

---

## Next Steps After Deployment

1. **Complete OpenEMR Setup**: Access the web interface and complete initial configuration
2. **Configure Vietnamese PT Module**: Follow `Documentation/physiotherapy/` guides
3. **Set Up Backups**: Configure automated database backups
4. **Create Additional Environments**: Replicate to staging/production
5. **Monitoring**: Set up monitoring and alerting

---

**Ready to deploy?** Just install the prerequisites and run the 4 scripts in order!

**Need help?** See the detailed guides:
- `infrastructure/homelab/DEPLOYMENT_GUIDE.md`
- `infrastructure/homelab/DEPLOYMENT_CHECKLIST.md`
- `infrastructure/homelab/IMPLEMENTATION_SUMMARY.md`
