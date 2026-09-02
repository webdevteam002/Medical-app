#!/bin/bash
# Daily PostgreSQL backup → local file (upload to R2 manually or via cron + rclone)
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/home/ubuntu/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE="$BACKUP_DIR/medstudy_$TIMESTAMP.sql.gz"

mkdir -p "$BACKUP_DIR"

docker exec medstudy-postgres pg_dump -U medstudy medstudy | gzip > "$FILE"

# Keep last 7 days
find "$BACKUP_DIR" -name "medstudy_*.sql.gz" -mtime +7 -delete

echo "Backup saved: $FILE"
