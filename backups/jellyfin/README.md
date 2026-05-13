A small script I threw into crontab. Would be nice if I could remove it sometime for a native jellyfin solution.
It creates a backup and prunes old ones.

Configurable environment variables (all have defaults in script):
- `PRUNE_DURATION_DAYS` (default: `60`) - keep backups for this many days
- `JELLYFIN_CONTAINER_NAME` (default: `jellyfin`) - container that runs Jellyfin (curl runs inside this container)
- `VOLUME_NAME` (default: `pi-compose_jellyfin_backup`) - Docker volume containing backups under `/var/lib/docker/volumes/<volume-name>/_data`

Required environment variables:
- `JELLYFIN_API_KEY`
