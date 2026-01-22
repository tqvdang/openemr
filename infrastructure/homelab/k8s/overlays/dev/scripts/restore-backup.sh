#!/bin/bash
# OpenEMR Database Restore Script
# Restores from pve1 SSD: /mnt/backups/openemr/
# Usage: ./restore-backup.sh <backup-filename>

set -e

PVE1="root@192.168.10.11"
BACKUP_DIR="/mnt/backups/openemr"

if [ -z "$1" ]; then
  echo "=== OpenEMR Database Restore ==="
  echo ""
  echo "Usage: $0 <backup-filename>"
  echo ""
  echo "Available backups on pve1:"
  ssh ${PVE1} "ls -lh ${BACKUP_DIR}/"
  exit 1
fi

BACKUP_FILE="$1"
REMOTE_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

# Check if file exists
if ! ssh ${PVE1} "test -f ${REMOTE_PATH}"; then
  echo "Error: Backup not found: ${REMOTE_PATH}"
  echo ""
  echo "Available backups:"
  ssh ${PVE1} "ls -lh ${BACKUP_DIR}/"
  exit 1
fi

echo "=== OpenEMR Database Restore ==="
echo ""
echo "WARNING: This will REPLACE the current database!"
echo "Backup file: pve1:${REMOTE_PATH}"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "Starting restore..."

# Stream from pve1 and restore
ssh ${PVE1} "cat ${REMOTE_PATH}" | gunzip | \
  kubectl -n openemr-dev exec -i deployment/openemr -c openemr -- \
    mariadb \
      -h openemr-db.trancloud.work \
      -u root \
      -p'ycm&17XK' \
      --ssl \
      --ssl-verify-server-cert=0 \
      openemr_dev

echo ""
echo "Restore complete!"
echo ""
echo "Restart OpenEMR to clear cache:"
echo "  kubectl -n openemr-dev rollout restart deployment/openemr"
