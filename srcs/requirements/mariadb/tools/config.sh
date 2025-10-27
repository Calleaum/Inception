#!/bin/bash

set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql
rm -f /run/mysqld/mysqld.sock

# INITIALISATION DE MARIADB SI NÉCESSAIRE
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[INFO] Initializing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# Démarrage temporaire de MariaDB sans réseau
mysqld --user=mysql --skip-networking &
pid="$!"

# Attente que MariaDB soit prêt (correction: utiliser root sans password)
until mysqladmin ping --silent 2>/dev/null; do 
    echo "[INFO] Waiting for MariaDB to be ready..."
    sleep 1
done

echo "[INFO] Creating database and users..."
mysql -u root << EOF
-- Création de la base de données
CREATE DATABASE IF NOT EXISTS \`${MDB_NAME}\`;

-- Création de l'utilisateur applicatif
CREATE USER IF NOT EXISTS '${MDB_USER}'@'%' IDENTIFIED BY '${MDB_PWD}';
CREATE USER IF NOT EXISTS '${MDB_USER}'@'localhost' IDENTIFIED BY '${MDB_PWD}';

-- Attribution des privilèges
GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO '${MDB_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO '${MDB_USER}'@'localhost';

-- Définition du mot de passe root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MDB_ROOT}';

-- Application des changements
FLUSH PRIVILEGES;
EOF

# Arrêt propre de MariaDB (correction: utiliser le password root défini)
mysqladmin -u root -p"${MDB_ROOT}" shutdown || kill "$pid"
wait "$pid" 2>/dev/null || true

echo "[INFO] Starting MariaDB..."
exec mysqld --user=mysql --bind-address=0.0.0.0 --port=3306