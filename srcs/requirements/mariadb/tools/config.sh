#!/bin/bash

set -e

# LECTURE DES SECRETS
if [ -f /run/secrets/db_password ]; then
    MDB_PWD=$(cat /run/secrets/db_password)
else
    echo "[ERROR] Secret db_password not found!"
    exit 1
fi

if [ -f /run/secrets/db_root_password ]; then
    MDB_ROOT=$(cat /run/secrets/db_root_password)
else
    echo "[ERROR] Secret db_root_password not found!"
    exit 1
fi

# NETTOYAGE DES FICHIERS DE LOCK ET SOCKET
mkdir -p /run/mysqld
rm -f /run/mysqld/mysqld.sock
rm -f /run/mysqld/mysqld.pid
rm -f /var/lib/mysql/*.pid
rm -f /var/lib/mysql/*.sock

# PERMISSIONS
chown -R mysql:mysql /run/mysqld /var/lib/mysql
chmod 755 /run/mysqld
chmod 700 /var/lib/mysql

# INITIALISATION DE MARIADB SI NÉCESSAIRE
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[INFO] Initializing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
    
    # Démarrage temporaire pour l'initialisation
    mysqld --user=mysql --skip-networking &
    pid="$!"
    
    # Attente que MariaDB soit prêt
    until mysqladmin ping --silent 2>/dev/null; do 
        echo "[INFO] Waiting for MariaDB to be ready..."
        sleep 1
    done
    
    echo "[INFO] Creating database and users..."
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS \`${MDB_NAME}\`;
CREATE USER IF NOT EXISTS '${MDB_USER}'@'%' IDENTIFIED BY '${MDB_PWD}';
CREATE USER IF NOT EXISTS '${MDB_USER}'@'localhost' IDENTIFIED BY '${MDB_PWD}';
GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO '${MDB_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO '${MDB_USER}'@'localhost';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MDB_ROOT}';
FLUSH PRIVILEGES;
EOF
    
    # Arrêt propre
    mysqladmin -u root -p"${MDB_ROOT}" shutdown || kill "$pid"
    wait "$pid" 2>/dev/null || true
else
    echo "[INFO] MariaDB already initialized, reusing existing data..."
fi

echo "[INFO] Starting MariaDB..."
exec mysqld --user=mysql --bind-address=0.0.0.0 --port=3306