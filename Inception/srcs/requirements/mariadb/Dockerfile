FROM debian:bookworm

# Installation des paquets nécessaires
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Création des dossiers requis
RUN mkdir -p /run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Copie des fichiers de configuration et du script d'initialisation
COPY tools/config.sh /config.sh
RUN chmod +x /config.sh

# Exposition du port
EXPOSE 3306

ENTRYPOINT ["/config.sh"]