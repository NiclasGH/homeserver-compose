# Home Server Compose
This is my raspberri pi homeserver in a docker compose file.
The root compose contains all the applications that build the base.

## Manual Setups
### DNS
To fully utilize Pihole as a network-wide ad-blocker, you need to configure it as your primary dns server for your network router. You also need to disable IPv6, as DHCPv6, as opposed to DHCPv4 is not a required protocol to implement. A lot of android phones *always* use the IPv6 DNS Server of Google.

### API Keys
- acme.sh: Requires cloudflare access token for dns and a general account token (or comparable if not using cloudflare)
- arr-stack: Requires a bunch of passing around of each others api keys. A more thorough setup guide is in the arr-stack directory
- homepage: Needs keys from within the applications to access metadata for the homepage dashboard

### Directories
Following directories are in the .gitignore and should not be checked in but are used by the stack:
Media files:
jellyfin/media/shows
jellyfin/media/movies

### VPN
Wireguard is not currently running in a container due to network issues I had. therefor it needs to be installed locally. The wireguard directory, provides an example config and some useful insights

### Modules
The default settings from homepage and pihole assumes, that you activate all modules. If you dont and something doesnt work, check the configuration of those!

## Application stacks
### Web/Domain
- Traefik: Acts as a docker-first reverse proxy. Can be configured using docker labels
- acme.sh: Uses the DNS Challenge to automate domain certificates. Right now I use cloudflare as my domain registrar
- pihole: DNS Server and ad-blocker. I utilize this for simplifying my vpn setup

### Media
- Jellyfin: Open Source Media Server
- Seerr: Used to request shows. Very useful when multiple people use the media server but only a few actually manage it.
- Filebrowser: Provides a web UI to download or upload files. In this setup it specifically only has access to the `jellyfin/media` directory

#### (Optional) ARR-Stack
- Sonarr: Automates tv show downloads
- Radarr: Automates movie downloads
- Prowlarr: Configures indexers for sonarr and radarr
- shadnzbd: Takes NZB files from Sonarr and Radarr, downloads them and offers them back
- gluetun: Failsafe VPN that connects to a VPN using my surfshark account. Blocks all outgoing network traffic, if the vpn is not available.

### VPN
- rathole: NAT Traversal service, that connects to a VPS where a rathole server is provided. The rathole server opens the wireguard port. This way clients from outside the private network can connect to the home server via wireguard, without having to publish the homenetwork ip or having to deal with dyndns. Could be replaced with tailscale

## Backups
Until actual backups are built: jellyfin db is checked into git, shows.txt is checked in
TODO
