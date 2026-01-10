# OpenEMR Homelab Deployment Guide

Complete guide to deploy OpenEMR to the homelab k3s cluster in pve2 with public access via HAProxy.

## Overview

This deployment creates:
- **MariaDB LXC** in pve2 (192.168.10.30) for database
- **OpenEMR** deployed to k3s cluster as a containerized application
- **HAProxy** routing via pfSense for public HTTPS access
- **Public URL**: https://openemr-dev.trancloud.work

## Architecture

```
Internet
   ↓
pfSense Router (192.168.10.1)
   ↓
HAProxy (HTTPS termination)
   ↓
DNS: openemr-dev.trancloud.work → 192.168.10.1
   ↓
Backend: openemr-dev-be → k3s NodePort 30090
   ↓
k3s Cluster (192.168.10.60-62)
   ↓
OpenEMR Pod (namespace: openemr-dev)
   ↓
MariaDB LXC (192.168.10.30:3306)
```

## Prerequisites

- [x] Proxmox pve2 access: https://pve2.trancloud.work (root / <PASSWORD_FROM_INFISICAL>)
- [x] pfSense access: https://pfsense.trancloud.work (dang / <PASSWORD_FROM_INFISICAL>)
- [x] k3s cluster running (master: 192.168.10.60)
- [x] kubectl configured to access k3s cluster

## Deployment Steps

### Phase 1: Database Setup (15 minutes)

Create MariaDB LXC container in pve2:

```bash
# Follow the detailed guide
cat infrastructure/homelab/docs/mariadb-lxc-setup.md

# Quick summary:
# 1. Login to pve2 web UI
# 2. Create LXC: CT ID 102, IP 192.168.10.30
# 3. Install MariaDB 11.x
# 4. Create database: openemr_dev
# 5. Create user: openemr_dev / <DB_PASSWORD_FROM_INFISICAL>
# 6. Configure remote access (bind-address = 0.0.0.0)
# 7. Test connection from k3s master
```

**Verification**:
```bash
# From k3s master or your workstation
mysql -h 192.168.10.30 -u openemr_dev -p openemr_dev
# Password: <DB_PASSWORD_FROM_INFISICAL>
```

### Phase 2: Kubernetes Deployment (10 minutes)

Deploy OpenEMR to k3s:

```bash
# Navigate to project root
cd /home/dang/dev/openemr

# Run deployment script
./infrastructure/homelab/scripts/deploy-dev.sh

# Or manual deployment:
kubectl apply -f infrastructure/homelab/k8s/namespaces/openemr-dev.yaml
kubectl apply -k infrastructure/homelab/k8s/overlays/dev/

# Wait for pod to be ready
kubectl get pods -n openemr-dev -w

# Check logs
kubectl logs -n openemr-dev -l app=openemr -f
```

**Verification**:
```bash
# Test NodePort access
curl http://192.168.10.60:30090

# Should return OpenEMR HTML or redirect
```

### Phase 3: pfSense HAProxy Configuration (10 minutes)

Configure HAProxy for public access:

```bash
# Follow the detailed guide
cat infrastructure/homelab/docs/pfsense-haproxy-config.md
```

**Quick Steps**:

1. **DNS Override** (Services → DNS Resolver → Host Overrides):
   - Host: openemr-dev
   - Domain: trancloud.work
   - IP: 192.168.10.1

2. **Backend** (Services → HAProxy → Backend):
   - Name: openemr-dev-be
   - Server: 192.168.10.60:30090
   - Health check: HTTP GET /

3. **Frontend ACL** (Services → HAProxy → Frontend → trancloud-https):
   - ACL: openemr-dev-acl (Host matches: openemr-dev.trancloud.work)
   - Action: Use Backend → openemr-dev-be

4. **Apply Changes** and verify in HAProxy Stats

**Verification**:
```bash
# Test internal DNS
nslookup openemr-dev.trancloud.work
# Should return: 192.168.10.1

# Test HTTPS access
curl -I https://openemr-dev.trancloud.work
# Should return: HTTP/1.1 200 OK (or 302 redirect)

# Browser test
open https://openemr-dev.trancloud.work
```

### Phase 4: Initial OpenEMR Setup (5 minutes)

1. Access OpenEMR: https://openemr-dev.trancloud.work

2. If first-time setup, OpenEMR will run installation wizard:
   - Follow on-screen instructions
   - Database already configured via environment variables
   - Create initial admin user

3. Login with credentials:
   - Username: admin
   - Password: <ADMIN_PASSWORD_FROM_INFISICAL> (or what you set in secrets.yaml)

### Phase 5: Optional - Public Internet Access

If you want OpenEMR accessible from the internet:

#### Option A: Cloudflare DNS (Recommended)

1. Login to Cloudflare dashboard
2. Add A record: openemr-dev → Your public IP
3. Enable proxy (orange cloud)
4. Set SSL mode to "Full (strict)"

#### Option B: Direct Port Forward

1. pfSense → Firewall → NAT → Port Forward
2. Forward WAN:443 → 192.168.10.1:443
3. Update public DNS to point to your IP

## Quick Reference

### URLs and Ports

| Service | Internal URL | Public URL |
|---------|-------------|------------|
| OpenEMR | http://192.168.10.60:30090 | https://openemr-dev.trancloud.work |
| MariaDB | 192.168.10.30:3306 | N/A (internal only) |
| k3s API | https://192.168.10.60:6443 | N/A (internal only) |

### Credentials

| Service | Username | Password |
|---------|----------|----------|
| pve2 | root | <PASSWORD_FROM_INFISICAL> |
| pfSense | dang | <PASSWORD_FROM_INFISICAL> |
| MariaDB root | root | <PASSWORD_FROM_INFISICAL> |
| MariaDB openemr | openemr_dev | <DB_PASSWORD_FROM_INFISICAL> |
| OpenEMR admin | admin | <ADMIN_PASSWORD_FROM_INFISICAL> |

### kubectl Commands

```bash
# View all resources
kubectl get all -n openemr-dev

# View pods
kubectl get pods -n openemr-dev

# View logs
kubectl logs -n openemr-dev -l app=openemr -f

# Describe pod
kubectl describe pod -n openemr-dev -l app=openemr

# Execute into pod
kubectl exec -it -n openemr-dev deployment/openemr -- sh

# Restart deployment
kubectl rollout restart deployment/openemr -n openemr-dev

# Delete and redeploy
kubectl delete -k infrastructure/homelab/k8s/overlays/dev/
kubectl apply -k infrastructure/homelab/k8s/overlays/dev/
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n openemr-dev

# Check pod events
kubectl describe pod -n openemr-dev -l app=openemr

# Common issues:
# - ImagePullBackOff: Check image name
# - CrashLoopBackOff: Check logs for errors
# - Pending: Check PVC status
```

### Cannot Connect to Database

```bash
# Test from pod
kubectl exec -it -n openemr-dev deployment/openemr -- sh
nc -zv 192.168.10.30 3306

# Test from k3s master
mysql -h 192.168.10.30 -u openemr_dev -p openemr_dev

# Check MariaDB logs
ssh root@pve2.trancloud.work
pct enter 102
tail -f /var/log/mysql/error.log
```

### HAProxy Returns 503

```bash
# Check backend status
# pfSense → Services → HAProxy → Stats

# Verify NodePort accessibility
curl http://192.168.10.60:30090

# Check pod status
kubectl get pods -n openemr-dev
```

### DNS Not Resolving

```bash
# Test DNS
nslookup openemr-dev.trancloud.work

# Test against pfSense directly
nslookup openemr-dev.trancloud.work 192.168.10.1

# Restart DNS Resolver in pfSense if needed
```

## Maintenance

### Updating OpenEMR

```bash
# Update image in deployment
kubectl set image deployment/openemr \
  openemr=openemr/openemr:flex-latest \
  -n openemr-dev

# Or edit deployment
kubectl edit deployment openemr -n openemr-dev

# Rollout new version
kubectl rollout status deployment/openemr -n openemr-dev
```

### Database Backup

```bash
# SSH to MariaDB LXC
ssh root@pve2.trancloud.work
pct enter 102

# Backup database
mysqldump -u root -p openemr_dev > /tmp/openemr_dev_backup_$(date +%Y%m%d).sql

# Compressed backup
mysqldump -u root -p openemr_dev | gzip > /tmp/openemr_dev_backup_$(date +%Y%m%d).sql.gz
```

### Viewing Logs

```bash
# OpenEMR application logs
kubectl logs -n openemr-dev -l app=openemr -f

# MariaDB logs
ssh root@pve2.trancloud.work
pct enter 102
tail -f /var/log/mysql/error.log

# HAProxy logs
ssh dang@pfsense.trancloud.work
tail -f /var/log/haproxy.log | grep openemr-dev
```

## Next Steps

1. Configure OpenEMR settings via Admin panel
2. Set up users and access controls
3. Configure Vietnamese Physiotherapy module (if needed)
4. Set up automated backups
5. Monitor application performance
6. Consider staging/production environments

## File Structure

```
infrastructure/homelab/
├── DEPLOYMENT_GUIDE.md          # This file
├── docs/
│   ├── mariadb-lxc-setup.md     # MariaDB LXC setup
│   └── pfsense-haproxy-config.md # HAProxy configuration
├── k8s/
│   ├── README.md                 # Kubernetes deployment docs
│   ├── namespaces/
│   │   └── openemr-dev.yaml     # Namespace definition
│   ├── base/                     # Base Kubernetes manifests
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   └── overlays/
│       └── dev/                  # Dev environment overlay
│           ├── kustomization.yaml
│           ├── configmap.yaml   # Configuration
│           ├── secrets.yaml     # Credentials
│           └── nodeport-service.yaml # External access
└── scripts/
    └── deploy-dev.sh            # Automated deployment script
```

## Support

- OpenEMR Documentation: https://www.open-emr.org/wiki/
- OpenEMR Community: https://community.open-emr.org/
- Project CLAUDE.md: /home/dang/dev/openemr/CLAUDE.md
- Homelab App Onboarding: .local/homelab-app-onboarding.md
