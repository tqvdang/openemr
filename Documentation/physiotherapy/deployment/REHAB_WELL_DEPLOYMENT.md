# Rehab Well PT - Kubernetes Deployment Guide

**Simplified Vietnamese Physiotherapy Clinic System**
*Deployment on K3s Homelab Cluster*

## Overview

This deployment configures OpenEMR as a focused PT clinic system for **Rehab Well**, stripping away unnecessary medical features to create a streamlined physiotherapy workflow.

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
│  │                  │ SSL │  (External LXC)  │              │
│  └──────────────────┘     └──────────────────┘              │
│           │                        │                         │
│           ▼                        ▼                         │
│  ┌──────────────────┐     ┌──────────────────┐              │
│  │  PVC: sites      │     │  Backup: pve1    │              │
│  │  (Persistent)    │     │  /mnt/backups/   │              │
│  └──────────────────┘     └──────────────────┘              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Reference

### URLs

| Service | URL |
|---------|-----|
| OpenEMR (Internal) | http://192.168.10.60:30090 |
| OpenEMR (External) | https://openemr-dev.trancloud.work |

### Credentials

#### Admin Accounts
```
openemr_admin / OpenEMR@2026$ecure!
dang.tran / RehabWell2026!
hoang.tran / RehabWell2026!
ben.dell / RehabWell2026!
```

#### Staff Accounts (Physiotherapist + Front Office)
```
linh.tang / RehabWell2026!
an.pham / RehabWell2026!
```

#### Database
```
Host: openemr-db.trancloud.work (192.168.10.30)
Database: openemr_dev
User: openemr_dev / openemr_dev_pass_2024
Root: root / ycm&17XK
SSL: Required
```

## User Roles

| Role | Value | Permissions |
|------|-------|-------------|
| Administrators | admin | Full system access |
| Physiotherapist | physio | PT clinical features |
| Clinicians | clin | General clinical access |
| Physicians | doc | Medical features |
| Front Office | front | Scheduling, patient intake |
| Accounting | back | Billing features |
| Emergency Login | breakglass | Emergency access |

Users can have multiple roles. Example: Staff with both `Physiotherapist` and `Front Office`.

## Simplified Interface

### Menu (6 items only)
- Calendar
- Finder
- Messages
- Patient
- Admin
- Reports

**Removed**: Flow, Recalls, Fees, Modules, Procedures, Miscellaneous, Popups

### Active Forms (7 only)
- Vietnamese PT Assessment
- Vietnamese PT Exercise Prescription
- Vietnamese PT Treatment Plan
- Vietnamese PT Outcome Measures
- Vitals
- SOAP
- New Encounter

### PT Appointment Types

| Type | Duration | Color |
|------|----------|-------|
| PT Initial Evaluation | 45 min | Green |
| PT Follow-up | 30 min | Blue |
| PT Exercise Session | 45 min | Purple |
| PT Re-evaluation | 30 min | Orange |

### Disabled Features
- Prescriptions, Lab, Immunizations
- CDR, AMC, CQM clinical rules
- Billing widgets, fees menu
- Insurance eligibility
- Patient portal, chart tracker
- 66 demographic fields hidden (126 → 60)

## Deployment Files

```
infrastructure/homelab/k8s/overlays/dev/
├── kustomization.yaml        # Main Kustomize config
├── configmap.yaml            # OpenEMR base config
├── secrets.yaml              # Database credentials
├── nodeport-service.yaml     # Port 30090 exposure
├── pt-configmap.yaml         # PT menu JSON
├── pt-sql-configmap.yaml     # PT SQL migrations
├── pt-setup-job.yaml         # K8s Job for PT config
├── backup-cronjob.yaml       # Automated backups (optional)
└── scripts/
    ├── backup-now.sh         # Manual backup
    └── restore-backup.sh     # Restore from backup
```

## Deployment Commands

### Initial Deployment
```bash
cd infrastructure/homelab/k8s
kubectl apply -k overlays/dev/
```

### Check Status
```bash
kubectl -n openemr-dev get pods,svc,jobs
kubectl -n openemr-dev logs deployment/openemr -f
```

### Re-run PT Configuration
```bash
kubectl -n openemr-dev delete job openemr-pt-setup --ignore-not-found
kubectl -n openemr-dev apply -f overlays/dev/pt-setup-job.yaml
```

### Restart OpenEMR
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

## Backup & Recovery

### Backup Location
```
pve1 (192.168.10.11)
└── /mnt/backups/openemr/
    └── openemr_dev_YYYYMMDD_HHMMSS.sql.gz
```

**Storage**: 100GB LVM thin volume from `ssd-scratch/data`
**Retention**: 7 days automatic cleanup

### Manual Backup
```bash
cd infrastructure/homelab/k8s/overlays/dev
./scripts/backup-now.sh
```

### List Backups
```bash
ssh root@192.168.10.11 "ls -lh /mnt/backups/openemr/"
```

### Restore from Backup
```bash
# List available backups
./scripts/restore-backup.sh

# Restore specific backup
./scripts/restore-backup.sh openemr_dev_20260121_213022.sql.gz

# Restart OpenEMR after restore
kubectl -n openemr-dev rollout restart deployment/openemr
```

### RTO Estimates
- Backup: ~2-5 minutes
- Restore: ~5-10 minutes
- Full recovery: ~15 minutes

## Adding New Users

### Via SQL (for bulk setup)

1. Edit `pt-sql-configmap.yaml` section `06-pt-users.sql`
2. Add entries to these tables:
   - `users` - User profile
   - `groups` - **Required** for authentication
   - `users_secure` - Password hash
   - `gacl_aro` - ACL entry
   - `gacl_groups_aro_map` - Role assignment
3. Re-run PT setup job
4. Set password via OpenEMR Admin UI

### Via OpenEMR Admin UI

1. Login as admin
2. Admin → Users → Add User
3. Fill required fields
4. Assign to appropriate group(s)

### Authentication Tables Reference

OpenEMR requires entries in **4 tables** for a user to authenticate:

| Table | Purpose |
|-------|---------|
| `users` | User profile (name, email, authorized, active) |
| `users_secure` | Password hash storage (bcrypt) |
| `groups` | **CRITICAL** - Maps user to group (e.g., 'Default') |
| `gacl_aro` + `gacl_groups_aro_map` | ACL permissions |

**Common Issue**: Missing `groups` table entry causes login failure even with correct password. The `UserService::getAuthGroupForUser()` method queries this table.

## Customization

### Change Facility Name
Edit `pt-sql-configmap.yaml`:
```yaml
05-pt-facility.sql: |
  UPDATE facility SET name = 'Your Clinic Name' WHERE id = 1;
```

### Modify Menu
Edit `pt-configmap.yaml` → `menu-standard.json`

### Enable/Disable Forms
Edit `pt-sql-configmap.yaml` → `03-pt-forms.sql`:
```sql
UPDATE registry SET state = 1 WHERE directory = 'form_name';  -- Enable
UPDATE registry SET state = 0 WHERE directory = 'form_name';  -- Disable
```

### Add New Appointment Type
Edit `pt-sql-configmap.yaml` → `02-pt-calendar.sql`:
```sql
INSERT INTO openemr_postcalendar_categories
  (pc_catname, pc_catcolor, pc_catdesc, pc_cattype, pc_active, pc_duration)
VALUES
  ('New Type', '#COLOR', 'Description', 0, 1, 30);
```

## Troubleshooting

### Pod Won't Start
```bash
kubectl -n openemr-dev describe pod -l app=openemr
kubectl -n openemr-dev logs deployment/openemr -c init-sites
```

### Database Connection Failed
- Verify `mariadb-ssl-ca` secret exists
- Check hostAliases in deployment (DNS resolution)
- Test: `kubectl -n openemr-dev exec deployment/openemr -- ping openemr-db.trancloud.work`

### Login Fails (Password Correct)
1. Check `groups` table has user entry
2. Check `users_secure` table has user entry
3. Check `gacl_aro` and `gacl_groups_aro_map` entries
4. Verify user is `active=1` and `authorized=1` in `users` table

### PT Config Not Applied
```bash
kubectl -n openemr-dev get jobs
kubectl -n openemr-dev logs job/openemr-pt-setup
kubectl -n openemr-dev delete job openemr-pt-setup
kubectl -n openemr-dev apply -f overlays/dev/pt-setup-job.yaml
```

## Infrastructure Reference

| Resource | Location |
|----------|----------|
| K8s Manifests | `infrastructure/homelab/k8s/overlays/dev/` |
| Base Deployment | `infrastructure/homelab/k8s/base/` |
| Infrastructure Config | `/home/dang/dev/infrastructure.yaml` |
| OpenEMR Source | `/home/dang/dev/openemr/` |
| Backup Scripts | `overlays/dev/scripts/` |
| PT SQL Configs | `overlays/dev/pt-config/` |

---

**Last Updated**: January 2026
**Version**: 1.0
**Author**: Dang Tran <tqvdang@msn.com>
