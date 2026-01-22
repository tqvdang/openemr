# Rehab Well PT - Quick Reference Card

## Access

```
URL: http://192.168.10.60:30090
```

## Credentials

### Admins
```
openemr_admin / OpenEMR@2026$ecure!
dang.tran / RehabWell2026!
hoang.tran / RehabWell2026!
ben.dell / RehabWell2026!
```

### Staff
```
linh.tang / RehabWell2026!
an.pham / RehabWell2026!
```

### Database
```
Host: openemr-db.trancloud.work
DB: openemr_dev
Root: root / ycm&17XK
```

## Common Commands

```bash
# Check status
kubectl -n openemr-dev get pods

# View logs
kubectl -n openemr-dev logs deployment/openemr -f

# Restart
kubectl -n openemr-dev rollout restart deployment/openemr

# Shell access
kubectl -n openemr-dev exec -it deployment/openemr -c openemr -- bash

# Database access
kubectl -n openemr-dev exec deployment/openemr -c openemr -- \
  mariadb -h openemr-db.trancloud.work -u root -p'ycm&17XK' \
  --ssl --ssl-verify-server-cert=0 openemr_dev
```

## Backup

```bash
# Manual backup
cd infrastructure/homelab/k8s/overlays/dev
./scripts/backup-now.sh

# List backups
ssh root@192.168.10.11 "ls -lh /mnt/backups/openemr/"

# Restore
./scripts/restore-backup.sh <filename>
```

## User Roles

| Role | For |
|------|-----|
| admin | Full access |
| physio | PT clinical |
| front | Scheduling |
| clin | General clinical |

## Troubleshooting

### Login fails?
```sql
-- Check groups table (REQUIRED for auth)
SELECT * FROM `groups` WHERE user = 'username';

-- Add if missing
INSERT INTO `groups` (name, user) VALUES ('Default', 'username');
```

### Pod crash?
```bash
kubectl -n openemr-dev describe pod -l app=openemr
kubectl -n openemr-dev logs deployment/openemr --previous
```

### Re-apply PT config?
```bash
kubectl -n openemr-dev delete job openemr-pt-setup
kubectl -n openemr-dev apply -f overlays/dev/pt-setup-job.yaml
```

---
*See REHAB_WELL_DEPLOYMENT.md for full documentation*
