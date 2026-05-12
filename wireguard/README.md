# Wireguard
Example config can be copied to `/etc/wireguard/`

Otherwise you just need to generate keys and put them into the example config.
Its also recommended to configure wireguard to start on system startup using:
```bash
sudo systemctl enable wg-quick@wg0
```

