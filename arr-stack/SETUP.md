# Setup Guide

This stack needs a bit of initial manual setup after containers are running.

## Image Versions and Startup

Before startup, follow the [host media storage prerequisites](../README.md#media-storage) and verify both NAS shares are mounted. From `arr-stack/`, link the example versions file before starting the stack:

```sh
ln .env.example .env
docker compose up -d
```

## Components

- `gluetun`: VPN container
- `prowlarr`: indexer manager
- `sonarr`: TV manager
- `radarr`: movie manager
- `sabnzbd`: download client

## Connection Flow

Configure these integrations:

- `prowlarr -> sonarr, radarr` (connection, indexers)
- `sonarr, radarr -> sabnzbd` (download client, download directories)
- `sabnzbd` (tv, movies category;download directory to /downloads)

## Call Usage Map

```text
                +-----------+
                |  gluetun  |
                |    VPN    |
                +-----------+

 +-----------+      indexers      +----------+
 | prowlarr  | -----------------> |  sonarr  |
 +-----------+                    +----------+
       |
       | indexers
       v
 +----------+
 |  radarr  |
 +----------+

 +----------+   download client   +----------+
 |  sonarr  | ------------------> | sabnzbd  |
 +----------+                     +----------+

 +----------+   download client   +----------+
 |  radarr  | ------------------> | sabnzbd  |
 +----------+                     +----------+
```

## Media Root Folders

In Sonarr and Radarr, go to **Settings → Media Management → Root Folders**. Add the appropriate TV or movie folders under `/data/media-local`, `/data/media-nas-1-lg`, and `/data/media-nas-2-sm`. If updating an existing installation, use the series/movie editor to point existing entries at their new root folders. If the files are already in place, decline any prompt to move them. Verify the new paths before removing obsolete root folders. Compose does not migrate files or app settings.

Imports from `/downloads` to another filesystem (for example, a NAS) cannot use hardlinks or atomic renames. They must copy the data instead, even if **Use Hardlinks instead of Copy** is enabled. Enable that option only if you also have imports for which the download and library paths share a filesystem and the container permits hardlinking between them.

## Required App Settings

In **both** Sonarr and Radarr, enable these advanced options:
- `Rename Episodes`
- `Add Quality Profile for 1080p German`
- `Add release year to folder name for Sonarr`
