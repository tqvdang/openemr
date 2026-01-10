# OpenEMR Kubernetes Deployment

This directory contains Kubernetes manifests for deploying OpenEMR to the homelab k3s cluster.

## Prerequisites

1. **MariaDB LXC Container** in pve2 at `192.168.10.30`:
   - Database: `openemr_dev`
   - User: `openemr_dev`
   - Password: Update in `overlays/dev/secrets.yaml`

2. **k3s Cluster** with nodes:
   - k3s-master: 192.168.10.60
   - k3s-worker1: 192.168.10.61
   - k3s-worker2: 192.168.10.62

3. **kubectl** configured to access the cluster

## Directory Structure

```
infrastructure/homelab/k8s/
├── base/                      # Base manifests
│   ├── kustomization.yaml
│   ├── deployment.yaml        # OpenEMR deployment
│   ├── service.yaml           # ClusterIP service
│   └── pvc.yaml              # Persistent volume claim
├── overlays/
│   └── dev/                   # Dev environment overlay
│       ├── kustomization.yaml
│       ├── configmap.yaml     # Database and app config
│       ├── secrets.yaml       # Credentials (update these!)
│       └── nodeport-service.yaml  # NodePort 30090
└── namespaces/
    └── openemr-dev.yaml       # Namespace definition
```

## Deployment Steps

### 1. Create MariaDB LXC in pve2

See `../docs/mariadb-lxc-setup.md` for instructions.

### 2. Update Secrets

Edit `overlays/dev/secrets.yaml` with your actual credentials:
```bash
nano overlays/dev/secrets.yaml
```

### 3. Deploy to k3s

```bash
# Apply namespace
kubectl apply -f namespaces/openemr-dev.yaml

# Deploy dev environment
kubectl apply -k overlays/dev/

# Verify deployment
kubectl get all -n openemr-dev
kubectl get pvc -n openemr-dev
```

### 4. Check Pod Status

```bash
# Watch pods coming up
kubectl get pods -n openemr-dev -w

# Check logs
kubectl logs -n openemr-dev -l app=openemr -f
```

### 5. Configure HAProxy

After deployment, configure pfSense HAProxy:

1. **DNS Override**: `openemr-dev.trancloud.work` → `192.168.10.1`
2. **Backend**: `openemr-dev-be` → `192.168.10.60:30090`
3. **ACL**: Host matches `openemr-dev.trancloud.work`
4. **Action**: Use backend `openemr-dev-be`

See `../../.local/homelab-app-onboarding.md` for detailed HAProxy configuration.

## Accessing OpenEMR

- **Internal**: http://192.168.10.60:30090
- **Public**: https://openemr-dev.trancloud.work (after HAProxy config)

## Default Credentials

- **Admin User**: admin
- **Admin Password**: <ADMIN_PASSWORD_FROM_INFISICAL> (update in secrets.yaml)

## Troubleshooting

### Check NodePort Accessibility
```bash
curl http://192.168.10.60:30090
```

### View Pod Logs
```bash
kubectl logs -n openemr-dev deployment/openemr
```

### Check Database Connection
```bash
kubectl exec -it -n openemr-dev deployment/openemr -- sh
# Inside pod:
nc -zv 192.168.10.30 3306
```

### Delete and Redeploy
```bash
kubectl delete -k overlays/dev/
kubectl apply -k overlays/dev/
```

## Environments

- **Dev**: `overlays/dev/` - Development environment (current)
- **Staging**: `overlays/staging/` - To be created
- **Production**: `overlays/prod/` - To be created

## Notes

- NodePort 30090 is used for external access via HAProxy
- Persistent storage uses k3s default `local-path` storage class
- Database runs on external PostgreSQL LXC (not in k8s)
- OpenEMR uses the official `openemr/openemr:flex` Docker image
