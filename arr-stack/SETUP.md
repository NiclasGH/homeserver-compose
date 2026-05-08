# Setup Guide

This stack needs a bit of initial manual setup after containers are running.

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

## Required App Settings

In **both** Sonarr and Radarr, enable these advanced options:
- `Hardlinks`
- `Rename Episodes`
- `Add Quality Profile for 1080p German`
- `Add release year to folder name for Sonarr`
