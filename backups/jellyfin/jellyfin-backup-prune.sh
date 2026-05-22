#!/usr/bin/env sh

set -eu

PRUNE_DURATION_DAYS="${PRUNE_DURATION_DAYS:-60}"
JELLYFIN_CONTAINER_NAME="${JELLYFIN_CONTAINER_NAME:-jellyfin}"
VOLUME_NAME="${VOLUME_NAME:-homeserver_jellyfin-backup}"


JELLYFIN_BASE_URL="http://127.0.0.1:8096"
JELLYFIN_BACKUP_ENDPOINT="/Backup/Create"
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:?JELLYFIN_API_KEY environment variable is required}"

BACKUP_VOLUME_PATH="/var/lib/docker/volumes/${VOLUME_NAME}/_data"

if [ ! -d "$BACKUP_VOLUME_PATH" ]; then
  printf 'Backup path does not exist: %s\n' "$BACKUP_VOLUME_PATH" >&2
  exit 1
fi

printf 'Triggering backup in container %s ...\n' "$JELLYFIN_CONTAINER_NAME"

docker exec "$JELLYFIN_CONTAINER_NAME" curl -fsS -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: MediaBrowser Token=$JELLYFIN_API_KEY" \
  -d '{"Database":true,"Metadata":false,"Trickplay":false,"Subtitles":false}' \
  "${JELLYFIN_BASE_URL}${JELLYFIN_BACKUP_ENDPOINT}"

printf 'Pruning backups older than %s days in %s ...\n' "$PRUNE_DURATION_DAYS" "$BACKUP_VOLUME_PATH"

find "$BACKUP_VOLUME_PATH" -type f -mtime "+$PRUNE_DURATION_DAYS" -print -exec rm {} +

printf 'Created backup and pruned old ones.\n'
