FROM debian:bookworm

# Installation des paquets nécessaires
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Création des répertoires requis
RUN mkdir -p /etc/nginx/ssl /run/nginx

# Copie de la configuration Nginx
COPY conf/default.conf /etc/nginx/nginx.conf

# Copie du script d'initialisation TLS
COPY tools/config.sh /config.sh
RUN chmod +x /config.sh

EXPOSE 443

ENTRYPOINT ["/config.sh"]

