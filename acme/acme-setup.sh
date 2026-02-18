acme.sh --register-account -m niclas.kuerschner@outlook.com
acme.sh --issue --dns dns_cf -d tira-misu.org -d '*.tira-misu.org'
./entry.sh daemon
