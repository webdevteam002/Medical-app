#!/usr/bin/env bash
# Sync local extracted qbank images to the API server uploads/images folder.
# Usage:
#   bash scripts/sync-question-images.sh /path/to/content/images ubuntu@92.5.56.120
set -euo pipefail

SRC="${1:-}"
HOST="${2:-ubuntu@92.5.56.120}"
KEY="${MEDSTUDY_SSH_KEY:-$TEMP/medstudy_oracle_key}"

if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "Usage: $0 /path/to/content/images [user@host]"
  exit 1
fi

ssh -i "$KEY" -o StrictHostKeyChecking=no "$HOST" "mkdir -p ~/backend/uploads/images"
rsync -avz -e "ssh -i $KEY -o StrictHostKeyChecking=no" \
  "$SRC"/ "$HOST":~/backend/uploads/images/
ssh -i "$KEY" -o StrictHostKeyChecking=no "$HOST" \
  "cd ~/backend && set -a && . ./.env && set +a && curl -s -X POST http://127.0.0.1:3000/v1/admin/question-images/reindex -H 'Authorization: Bearer unused' || true; pm2 restart backend --update-env"
echo "Synced. Open Admin → Questions → Rebuild index (or restart backend) if needed."
