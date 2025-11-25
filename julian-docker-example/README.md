# homelab Beispiel

## Konzept
Im Grundprinzip laufen einige Webservices in Docker in einem geschlossenen Netzwerk. Vorne weg sitzt ein Reverse-Proxy, der als einziges http & https ports ans hostsystem exposed. Über einen sidecar container `docker-gen` wird gescannt welche Container gerade laufen und ob sie bestimmte environment variables gesetzt haben. Wenn Ja, werden für diese nginx configs generiert für http auf https weiterleitung und https auf proxy_pass zum container. Diese werden dann automatisch im reverse proxy abgelegt.
Zusätzlich dazu hat der Stack ein Sidecar Container, der ein Wrapper um [acme-sh](https://github.com/acmesh-official/acme.sh) ist. Dieser scannt die laufenden Container nach dem Attribut `LETSENCRYPT_HOST` in den environment variables und besorgt für die dort angegebenen Domains SSL-Zertifikate bei Lets Encrypt. Zusätzlich prüft er einmal pro Stunde deren Gültigkeit und erneuert sie falls notwendig.

## Reverse Proxy und Proxy-Generator
Der Reverse Proxy selbst ist ein simpler nginx, der die configs reingereicht bekommt und als einziges Ports exposed.
```yaml
  proxy:
    image: nginx:${PROXY_VERSION}
    container_name: proxy                           # Einfacher zum inspecten des containers, da fester Name
    labels:
      - com.github.nginx-proxy.nginx=true           # Label notwendig, damit der generator container diesen als proxy identifiziert
    depends_on:
      - proxy-generator
    ports:
      - 443:443
      - 80:80
    volumes:
      - conf:/etc/nginx/conf.d                      # Hier wird die generierte Config abgelegt
      - html:/usr/share/nginx/html                  # kp ob das wirklich notwendig ist, müsste man mal ins volume schauen
      - certs:/etc/nginx/certs                      # Hier werden die Zertifikate vom ACME abgelegt
      - ./proxy-default/homelab.conf:/etc/nginx/conf.d/homelab.conf:ro  # Hier werden defaults vom nginx überschrieben
      - ./proxy-vhost:/etc/nginx/vhost.d:ro         # Hier werden einzelne vhost overrides abgelegt
    networks:
      - local
```

Der Proxy-Generator ist ein in go geschriebenes open-source Projekt, welches die nginx configs generiert mit einem .tmpl file:
```yaml
  proxy-generator:
    image: nginxproxy/docker-gen:${PROXY_GENERATOR_VERSION}
    container_name: proxy-generator                 # Einfacher zum inspecten des containers, da fester Name
    command: -config /etc/nginx/config/config.cfg
    labels:
      - com.github.nginx-proxy.docker-gen=true      # Label notwendig für acme container
    depends_on:
      - gitlab                                      # Würd ich erst hochfahren lassen, wenn fachliche container ready sind
    volumes:
      - conf:/etc/nginx/conf.d                      # Zielvolume für generierte configs
      - html:/usr/share/nginx/html
      - certs:/etc/nginx/certs                      # unsicher ob er die wirklich brauch lol
      - ./proxy-vhost:/etc/nginx/vhost.d:ro         # vhost overrides
      - ./proxy-generator/config.cfg:/etc/nginx/config/config.cfg       # config datei für generelle Einstellungen des generators
      - ./proxy-generator/nginx.tmpl:/etc/nginx/templates/nginx.tmpl    # nginx template file, woraus die config generiert wird
      - /var/run/docker.sock:/tmp/docker.sock:ro    # Docker Socket, um laufende Container zu sehen
    networks:
      - local
```

Der Proxy-Generator scannt über den Docker Socket laufende Container nach folgenden Environment Variablen:
* `VIRTUAL_HOST`: Domain oder komma-separierte Domains, für die vom reverse proxy auf diesen Container geproxed werden soll
* `VIRTUAL_PORT`: Der genutzte Port vom Programm im image (Bspw 8080 von Spring, 3000 von Grafana etc). Nicht dem host-system exposed, aber dem Container exposed.
* `PROXY_ADDRESS_FORWARDING`: boolean, ob dem Container die ip addresse des aufrufenden Clients weitergegeben werden soll (recommended: true)

Das nginx.tmpl File gibts [hier im Repo vom docker-gen](https://github.com/nginx-proxy/docker-gen/blob/main/templates/nginx.tmpl).

### Warum zwei Container?
Es gibt auch ein Image, welches beides macht (nginx proxy und generieren von configs) namens [nginxproxy/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy). Die Dokumentation dort ist super, um das Warum und Wie zu verstehen, aber man will diese Container lieber trennen, um keinen Container zu exposen, der Zugriff auf den Docker Socket hat. Im Falle eines Security Breaches im proxy hätte der Angreifer dann Zugriff auf alle Container.

## ACME
Das gesamte Setup ist zum Bereitstellen von Webdiensten. Wo kommen wir hin, wenn wir das nur mit http machen ohne SSL?
Lets Encrypt stellt kostenlos SSL-Zertifikate aus für jeden, der welche braucht. Das bietet sich super für eine Automatisierung an.
```yaml
  acme:
    image: nginxproxy/acme-companion:${ACME_VERSION}
    container_name: acme                    # Einfacher zum inspecten des containers, da fester Name
    depends_on:
      - proxy
      - proxy-generator
    env_file:
      - acme/.env                           # Ich mag Organisation über sub-env-files lieber als eine riesige docker-compose yaml
    volumes:
      - conf:/etc/nginx/conf.d
      - html:/usr/share/nginx/html
      - certs:/etc/nginx/certs              # Zielvolume für angefragte Zertifikate
      - acme:/etc/acme.sh                   # Volume für acme.sh falls man noch direkt was dran ändern will
      - /var/run/docker.sock:/var/run/docker.sock:ro    # Docker Socket, um laufende Container zu sehen
    networks:
      - local
```

Der ACME Companion scannt über den Docker Socket laufende Container nach der Environment Variable `LETSENCRYPT_HOST`, um für den Wert dahinter (eine Domain oder komma-separierte Liste von Domains) Zertifikate bei Lets Encrypt zu besorgen.

### ACME Challenge
Auf welche Art ACME Zertifikate besorgen soll hängt vom Anwendungsfall ab. 
Ist das Ziel den Stack im open web zu hosten auf bspw einem VPS mit fester IP-Addresse, sollte eine http-challenge erfolgen.
Hierbei macht man manuell in einem public DNS (normalerweise wo man die domain gekauft hat) A Records für die subdomains, die man nutzen will und lässt sie auf die IP-Addresse des Hosts zeigen. Der Proxy regelt die Challenge von selbst und bestätigt in http calls die Anfragen von Lets Encrypt, sodass valide Zertifikate entstehen.
Wie man das Konfiguriert sieht man [hier](https://github.com/nginx-proxy/acme-companion/blob/main/docs/Docker-Compose.md). Spoiler: man muss eig nur die E-Mail als environment variable setzen am ACME Container.

Ist das Ziel den Stack im privaten Netzwerk zu hosten, dann macht es Sinn eine DNS-Challenge zu nutzen. Hierbei trägt acme.sh beim besorgen der Zertifikate über eine DNS API bei deinem public DNS (normalerweise wo man die domain gekauft hat) irwelche Zonen (kp was genau abgeht) ein. Lets Encrypt prüft das, um festzustellen, dass dem Antragsteller die Domain gehört und stellt das Zertifikat aus. Danach löscht acme.sh den Eintrag aus dem public DNS wieder. Man muss nur in seinem lokalen DNS (meistens ein Dienst vom Router) einen festen A-Record Eintrag auf die interne IP-Addresse des Hosts machen.
Eine Liste von DNS-Challenge Implementierungen gibt es [hier](https://github.com/acmesh-official/acme.sh/tree/master/dnsapi).

Konfigurieren tut man das über die Environment variables `ACME_CHALLENGE=DNS-01` und `ACMESH_DNS_API_CONFIG`. Näheres dazu [hier](https://github.com/nginx-proxy/acme-companion/blob/main/docs/Let's-Encrypt-and-ACME.md#dns-01-acme-challenge). Welche Environment variables man in der `ACMESH_DNS_API_CONFIG` überschreiben muss findet man beim jeweiligen provider auf [dieser Wiki page](https://github.com/acmesh-official/acme.sh/wiki/dnsapi).

## Netzwerk Konfiguration
Warum folgender block?

```yaml
networks:
  local:
    driver: bridge
    ipam:
      config:
        - subnet: 10.5.0.0/16
          gateway: 10.5.0.1
```
Das subnet zu konfigurieren ist erstmal normal. Alle ausgestellten IPv4 Addressen vom Docker DHCP sind im 10.5.0.0/16 bereich. Das Gateway soll auf der 10.5.0.1 laufen, weil ich mal in dem Setup einen Wireguard container laufen ließ, um sich von außen direkt ins docker subnet per VPN einzuwählen. Das ermöglicht das Hinzufügen von location overrides für bestimmte pfade im reverse proxy, sodass nur interne mit dem vpn verbundene clients diese Endpunkte aufrufen dürfen.

Ein Beispiel von einem Keycloak Container, aus `./proxy-vhost/<keycloak.domain>_location_override`:
```conf
location / {
    allow 10.5.0.1;
    deny all;
    proxy_pass http://<keycloak.domain>;
    set $upstream_keepalive false;
}

location /admin {
    allow 10.5.0.1;
    deny all;
    proxy_pass http://<keycloak.domain>;
    set $upstream_keepalive false;
}

location /js {
    proxy_pass http://<keycloak.domain>;
    set $upstream_keepalive false;
}

location /realms {
    proxy_pass http://<keycloak.domain>;
    set $upstream_keepalive false;
}

location /realms/master {
    allow 10.5.0.1;
    deny all;
    proxy_pass http://<keycloak.domain>;
    set $upstream_keepalive false;
}

# ...
```
Hier ist zwar nicht richtig konfiguriert, dass die IP-Addressen der VPN Clients genommen und ein "allow 10.5.0.0/16" verwendet wird, aber das Prinzip passt. Nur bestimmte Endpunkte sind freigegeben für alle Clients und einige hinter ip address block. Wird tatsächlich so [von keycloak recommended](https://www.keycloak.org/server/reverseproxy#_exposed_path_recommendations).

Näheres zum überschreiben von vhosts [hier](https://github.com/nginx-proxy/nginx-proxy/tree/main/docs#overriding-location-blocks).

## Fachliche Anwendungen
Wie fügt man denn jetzt neue Web-Dienste hinzu? Das geht super einfach. Man schreibt normal Docker Compose für die Anwendung und fügt die environment variablen für den proxy generator und acme hinzu und lässt den container im gleichen network laufen wie den proxy.
Ein Beispiel an diesem gitlab container:
```yaml
gitlab:
    image: gitlab/gitlab-ce:${GITLAB_VERSION}
    container_name: gitlab          # nicht notwendig, aber geiler für docker ps und inspection
    restart: always                 # nicht notwendig, außer man will, dass bei systemstart das ausgeführt wird
    hostname: "git.gersch.dev"      # nicht notwendig
    env_file:
      - gitlab/.env
    environment:
      PROXY_ADDRESS_FORWARDING: true
      VIRTUAL_HOST: git.gersch.dev              # diese domain auf diesen container proxen
      VIRTUAL_PORT: 80                          # von gitlab intern genutzter port für die weboberfläche
      LETSENCRYPT_HOST: git.gersch.dev          # ein Zertifikat für diese Domain bitte
    volumes:
      - "/srv/gitlab/config:/etc/gitlab"        # gitlab spezifisches volume
      - "./logs/gitlab:/var/log/gitlab"         # gitlab spezifisches volume
      - "/srv/gitlab/data:/var/opt/gitlab"      # gitlab spezifisches volume
    shm_size: "256m"                            # gitlab spezifisch, vorgegeben vom installation guide
    networks:
      - local
```

Ein noch einfacheres Beispiel gibt es [hier](https://github.com/nginx-proxy/nginx-proxy/tree/main/docs#docker-compose).
