# OpenEMR Vietnamese PT - Kubernetes Deployment (Dev)

This deployment configures OpenEMR as a **simplified Vietnamese Physiotherapy (PT) clinic system** for **Rehab Well**.

## Quick Start

```bash
# Deploy everything
kubectl apply -k overlays/dev/

# Check status
kubectl -n openemr-dev get pods,svc,jobs

# Access
# URL: http://192.168.10.60:30090
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    K3s Cluster (Homelab)                     │
│  Nodes: 192.168.10.60, 192.168.10.61, 192.168.10.62         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐     ┌──────────────────┐              │
│  │  OpenEMR Pod     │     │  MariaDB         │              │
│  │  (NodePort:30090)│────▶│  192.168.10.30   │              │
│  │                  │ SSL │  (External)      │              │
│  └──────────────────┘     └──────────────────┘              │
│           │                                                  │
│           ▼                                                  │
│  ┌──────────────────┐                                       │
│  │  PVC: sites      │                                       │
│  │  (Persistent)    │                                       │
│  └──────────────────┘                                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
overlays/dev/
├── README.md                 # This file
├── kustomization.yaml        # Main Kustomize config
├── configmap.yaml            # OpenEMR base config (db_host, etc.)
├── secrets.yaml              # Database credentials (sealed)
├── nodeport-service.yaml     # Expose on port 30090
├── pt-configmap.yaml         # PT custom menu JSON
├── pt-sql-configmap.yaml     # PT SQL migrations (globals, forms, etc.)
├── pt-setup-job.yaml         # K8s Job to apply PT config
└── pt-config/                # Source SQL files (reference)
    ├── 01-pt-globals.sql
    ├── 02-pt-calendar.sql
    ├── 03-pt-forms.sql
    ├── 04-pt-demographics.sql
    └── 05-pt-facility-users.sql
```

## Credentials

### OpenEMR Admin Accounts

| Username | Name | Role | Password |
|----------|------|------|----------|
| `openemr_admin` | Administrator | Super Admin | `OpenEMR@2026$ecure!` |
| `dang.tran` | Dang Tran | Admin | `RehabWell@2026!Dang` |
| `hoang.tran` | Hoang Tran | Admin | `RehabWell@2026!Hoang` |
| `ben.dell` | Ben Dell | Admin | `RehabWell@2026!Ben` |

### Database

| Setting | Value |
|---------|-------|
| Host | `openemr-db.trancloud.work` (192.168.10.30) |
| Database | `openemr_dev` |
| User | `openemr_dev` |
| Password | `openemr_dev_pass_2024` |
| Root Password | `ycm&17XK` |
| SSL | Required (CA in `mariadb-ssl-ca` secret) |

## PT Configuration Applied

### Simplified Menu (6 items)
- Calendar, Finder, Messages, Patient, Admin, Reports
- Removed: Flow, Recalls, Fees, Modules, Procedures, Miscellaneous, Popups

### Active Forms (7 only)
- Vietnamese PT Assessment
- Vietnamese PT Exercise Prescription
- Vietnamese PT Treatment Plan
- Vietnamese PT Outcome Measures
- Vitals, SOAP, New Encounter

### PT Appointment Types
| Type | Duration | Color |
|------|----------|-------|
| PT Initial Evaluation | 45 min | Green |
| PT Follow-up | 30 min | Blue |
| PT Exercise Session | 45 min | Purple |
| PT Re-evaluation | 30 min | Orange |

### Disabled Features
- Prescriptions, Lab, Immunizations, CDR, AMC, CQM
- Billing widgets, fees menu, insurance eligibility
- Patient portal, chart tracker
- 66 demographic fields hidden (126 → 60)
- Family/social history fields hidden

## Deployment Commands

### Full Deployment
```bash
cd infrastructure/homelab/k8s
kubectl apply -k overlays/dev/
```

### Check Status
```bash
kubectl -n openemr-dev get all
kubectl -n openemr-dev logs deployment/openemr -f
kubectl -n openemr-dev logs job/openemr-pt-setup
```

### Re-run PT Configuration Job
```bash
# Delete old job first (jobs are immutable)
kubectl -n openemr-dev delete job openemr-pt-setup --ignore-not-found
kubectl -n openemr-dev apply -f overlays/dev/pt-setup-job.yaml
```

### Restart OpenEMR Pod
```bash
kubectl -n openemr-dev rollout restart deployment/openemr
```

### Access Pod Shell
```bash
kubectl -n openemr-dev exec -it deployment/openemr -c openemr -- /bin/bash
```

### Database Access
```bash
kubectl -n openemr-dev exec deployment/openemr -c openemr -- \
  mariadb -h openemr-db.trancloud.work -u root -p'ycm&17XK' \
  --ssl --ssl-verify-server-cert=0 openemr_dev
```

## Customization

### Change Facility Name
Edit `pt-sql-configmap.yaml`:
```yaml
05-pt-facility.sql: |
  UPDATE facility SET name = 'Your Clinic Name' WHERE id = 1;
```

### Add New Admin User
1. Edit `pt-sql-configmap.yaml` section `06-pt-users.sql`
2. Add user INSERT statement
3. Re-run the PT setup job
4. Set password via PHP (bcrypt hashing required)

### Modify Menu
Edit `pt-configmap.yaml` → `menu-standard.json`

### Enable/Disable Forms
Edit `pt-sql-configmap.yaml` → `03-pt-forms.sql`:
```sql
UPDATE registry SET state = 1 WHERE directory = 'form_directory_name';
```

## Troubleshooting

### Pod Won't Start
```bash
kubectl -n openemr-dev describe pod -l app=openemr
kubectl -n openemr-dev logs deployment/openemr -c init-sites
```

### Database Connection Failed
- Check `mariadb-ssl-ca` secret exists
- Verify hostAliases in deployment (DNS resolution)
- Test: `kubectl -n openemr-dev exec deployment/openemr -- ping openemr-db.trancloud.work`

### PT Config Not Applied
```bash
# Check job status
kubectl -n openemr-dev get jobs
kubectl -n openemr-dev logs job/openemr-pt-setup

# Re-run job
kubectl -n openemr-dev delete job openemr-pt-setup
kubectl -n openemr-dev apply -f overlays/dev/pt-setup-job.yaml
```

### Menu Not Simplified
The menu is mounted from ConfigMap. Check:
```bash
kubectl -n openemr-dev exec deployment/openemr -c openemr -- \
  cat /var/www/localhost/htdocs/openemr/interface/main/tabs/menu/menus/standard.json
```

## Related Files

- **Base deployment**: `../../base/deployment.yaml`
- **OpenEMR Docker image**: `registry.trancloud.work/openemr-homelab:dev-v4`
- **Main OpenEMR docs**: `/home/dang/dev/openemr/CLAUDE.md`
- **PT Module docs**: `/home/dang/dev/openemr/Documentation/physiotherapy/`

## Maintenance

### Backup Database
```bash
kubectl -n openemr-dev exec deployment/openemr -c openemr -- \
  mysqldump -h openemr-db.trancloud.work -u root -p'ycm&17XK' \
  --ssl --ssl-verify-server-cert=0 openemr_dev > backup.sql
```

### Update OpenEMR Image
Edit `../../base/deployment.yaml`:
```yaml
image: registry.trancloud.work/openemr-homelab:dev-v5
```
Then: `kubectl apply -k overlays/dev/`
