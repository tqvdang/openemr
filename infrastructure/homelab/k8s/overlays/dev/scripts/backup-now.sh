#!/bin/bash
# OpenEMR Database Backup Script
# Backs up to pve1 SSD: /mnt/backups/openemr/
# Usage: ./backup-now.sh

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="openemr_dev_${TIMESTAMP}.sql.gz"
REMOTE_PATH="/mnt/backups/openemr/${BACKUP_FILE}"
PVE1="root@192.168.10.11"

echo "=== OpenEMR Database Backup ==="
echo "Timestamp: ${TIMESTAMP}"
echo "Target: pve1:${REMOTE_PATH}"
echo ""

# Run mysqldump from K8s pod and stream to pve1
echo "Starting backup..."
kubectl -n openemr-dev exec deployment/openemr -c openemr -- \
  mariadb-dump \
    -h openemr-db.trancloud.work \
    -u root \
    -p'ycm&17XK' \
    --ssl \
    --ssl-verify-server-cert=0 \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    openemr_dev | gzip | ssh ${PVE1} "cat > ${REMOTE_PATH}"

echo ""
echo "Backup complete!"
ssh ${PVE1} "ls -lh ${REMOTE_PATH}"

# Show retention (keep last 7 days)
echo ""
echo "Cleaning old backups (keeping 7 days)..."
ssh ${PVE1} "find /mnt/backups/openemr -name 'openemr_dev_*.sql.gz' -mtime +7 -delete"

echo ""
echo "Current backups:"
ssh ${PVE1} "ls -lh /mnt/backups/openemr/"
