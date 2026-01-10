# OpenEMR Homelab Infrastructure

This directory contains all infrastructure-as-code and deployment documentation for running OpenEMR in the homelab environment.

## Quick Start

**New to this deployment?** Start here:

1. Read: [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md) - Complete deployment overview
2. Follow: [`DEPLOYMENT_CHECKLIST.md`](DEPLOYMENT_CHECKLIST.md) - Step-by-step checklist
3. Deploy: Run `./scripts/deploy-dev.sh` when ready

## Directory Structure

```
infrastructure/homelab/
├── README.md                      # This file
├── DEPLOYMENT_GUIDE.md            # Complete deployment guide
├── DEPLOYMENT_CHECKLIST.md        # Step-by-step checklist
│
├── docs/                          # Detailed documentation
│   ├── mariadb-lxc-setup.md      # MariaDB LXC container setup
│   └── pfsense-haproxy-config.md # HAProxy reverse proxy configuration
│
├── k8s/                           # Kubernetes manifests
│   ├── README.md                  # Kubernetes deployment docs
│   ├── namespaces/
│   │   └── openemr-dev.yaml      # Namespace definition
│   ├── base/                      # Base manifests (reusable)
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml       # OpenEMR deployment
│   │   ├── service.yaml          # ClusterIP service
│   │   └── pvc.yaml              # Persistent volume claim
│   └── overlays/
│       └── dev/                   # Dev environment specific
│           ├── kustomization.yaml
│           ├── configmap.yaml    # Database config, URLs
│           ├── secrets.yaml      # Credentials (git-ignored)
│           └── nodeport-service.yaml # External access
│
└── scripts/                       # Automation scripts
    └── deploy-dev.sh             # Automated k8s deployment
```

## Deployment Overview

### Architecture

```
Internet → pfSense (HAProxy) → k3s Cluster → OpenEMR Pod
                                             ↓
                                      MariaDB LXC (pve2)
```

### Components

| Component | Location | IP | Access |
|-----------|----------|-----|---------|
| MariaDB LXC | pve2 | 192.168.10.30 | Internal only |
| k3s Master | pve1 | 192.168.10.60 | Internal only |
| k3s Worker 1 | pve1 | 192.168.10.61 | Internal only |
| k3s Worker 2 | pve2 | 192.168.10.62 | Internal only |
| HAProxy | pfSense | 192.168.10.1 | Port 443 (HTTPS) |
| OpenEMR Dev | k3s | NodePort 30090 | https://openemr-dev.trancloud.work |

## Deployment Process

### Phase 1: Database (15-20 min)
1. Create MariaDB LXC in pve2 via Proxmox web UI
2. Install MariaDB, create database and user
3. Configure for remote connections
4. Test connectivity

**Guide**: [`docs/mariadb-lxc-setup.md`](docs/mariadb-lxc-setup.md)

### Phase 2: Kubernetes (10 min)
1. Deploy namespace and application to k3s
2. Verify pod is running
3. Test NodePort access

**Guide**: [`k8s/README.md`](k8s/README.md)

**Script**: `./scripts/deploy-dev.sh`

### Phase 3: HAProxy (10 min)
1. Configure DNS override in pfSense
2. Create HAProxy backend
3. Add ACL and routing rule
4. Verify in HAProxy stats

**Guide**: [`docs/pfsense-haproxy-config.md`](docs/pfsense-haproxy-config.md)

### Phase 4: Testing (5 min)
1. Test internal access
2. Test public HTTPS access
3. Verify SSL certificate
4. Complete OpenEMR setup

## Quick Commands

### Deployment
```bash
# Automated deployment (recommended)
./infrastructure/homelab/scripts/deploy-dev.sh

# Manual deployment
kubectl apply -f infrastructure/homelab/k8s/namespaces/openemr-dev.yaml
kubectl apply -k infrastructure/homelab/k8s/overlays/dev/
```

### Monitoring
```bash
# View all resources
kubectl get all -n openemr-dev

# View logs
kubectl logs -n openemr-dev -l app=openemr -f

# Check pod status
kubectl get pods -n openemr-dev -w
```

### Troubleshooting
```bash
# Describe pod
kubectl describe pod -n openemr-dev -l app=openemr

# Execute into pod
kubectl exec -it -n openemr-dev deployment/openemr -- sh

# Test database connection from pod
kubectl exec -it -n openemr-dev deployment/openemr -- nc -zv 192.168.10.30 3306

# Restart deployment
kubectl rollout restart deployment/openemr -n openemr-dev
```

### Testing
```bash
# Test DNS
nslookup openemr-dev.trancloud.work

# Test NodePort
curl http://192.168.10.60:30090

# Test HTTPS
curl -I https://openemr-dev.trancloud.work
```

## Access URLs

- **Internal**: http://192.168.10.60:30090
- **Public**: https://openemr-dev.trancloud.work
- **MariaDB**: 192.168.10.30:3306 (internal only)

## Credentials

See [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md) for complete credential list.

| Service | Username | Password |
|---------|----------|----------|
| OpenEMR Admin | admin | <ADMIN_PASSWORD_FROM_INFISICAL> |
| MariaDB | openemr_dev | <DB_PASSWORD_FROM_INFISICAL> |

## Environment Variables

Configured in `k8s/overlays/dev/`:

- `configmap.yaml` - Non-sensitive configuration
- `secrets.yaml` - Passwords and sensitive data (git-ignored in production)

## Future Environments

Create additional overlays for staging and production:

```bash
# Staging
mkdir -p k8s/overlays/staging
cp -r k8s/overlays/dev/* k8s/overlays/staging/
# Edit staging configs

# Production
mkdir -p k8s/overlays/prod
cp -r k8s/overlays/dev/* k8s/overlays/prod/
# Edit production configs
```

## Maintenance

### Database Backup
```bash
ssh root@pve2.trancloud.work
pct enter 102
mysqldump -u root -p openemr_dev > /tmp/backup_$(date +%Y%m%d).sql
```

### Application Update
```bash
# Update image tag
kubectl set image deployment/openemr openemr=openemr/openemr:flex-latest -n openemr-dev

# Check rollout status
kubectl rollout status deployment/openemr -n openemr-dev
```

### Scaling
```bash
# Scale up
kubectl scale deployment/openemr --replicas=3 -n openemr-dev

# Scale down
kubectl scale deployment/openemr --replicas=1 -n openemr-dev
```

## Support

- **Deployment Guide**: [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md)
- **Checklist**: [`DEPLOYMENT_CHECKLIST.md`](DEPLOYMENT_CHECKLIST.md)
- **Homelab Process**: [`../../.local/homelab-app-onboarding.md`](../../.local/homelab-app-onboarding.md)
- **OpenEMR Docs**: https://www.open-emr.org/wiki/
- **OpenEMR Community**: https://community.open-emr.org/

## Troubleshooting

Common issues and solutions in [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md#troubleshooting).

Quick checks:
1. Is MariaDB running? `nc -zv 192.168.10.30 3306`
2. Are k8s pods running? `kubectl get pods -n openemr-dev`
3. Is HAProxy backend green? Check pfSense → HAProxy → Stats
4. Does DNS resolve? `nslookup openemr-dev.trancloud.work`

## Contributing

When modifying infrastructure:
1. Update relevant documentation
2. Test changes in dev environment
3. Update this README if structure changes
4. Keep credentials out of git (use secrets.yaml locally)

---

Last Updated: 2026-01-01
Maintained by: dang
Environment: homelab.trancloud.work
