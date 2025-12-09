#!/bin/bash

set -e

# READING SECRETS
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

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql
rm -f /run/mysqld/mysqld.sock

# INITIALIZE MARIADB IF NECESSARY
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[INFO] Initializing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# TEMPORARY START OF MARIADB WITHOUT NETWORKING
mysqld --user=mysql --skip-networking &
pid="$!"

# WAIT UNTIL MARIADB IS READY
until mysqladmin ping --silent 2>/dev/null; do 
    echo "[INFO] Waiting for MariaDB to be ready..."
    sleep 1
done

echo "[INFO] Creating database and users..."
mysql -u root -p"${MDB_ROOT}" << EOF

-- CREATE DATABASE
CREATE DATABASE IF NOT EXISTS \`${MDB_NAME}\`;

-- CREATE APPLICATION USER
CREATE USER IF NOT EXISTS '${MDB_USER}'@'%' IDENTIFIED BY '${MDB_PWD}';
CREATE USER IF NOT EXISTS '${MDB_USER}'@'localhost' IDENTIFIED BY '${MDB_PWD}';

-- GRANT PRIVILEGES
GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO '${MDB_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO '${MDB_USER}'@'localhost';

-- SET ROOT PASSWORD
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MDB_ROOT}';

-- APPLY CHANGES
FLUSH PRIVILEGES;
EOF

# CLEAN SHUTDOWN OF MARIADB
mysqladmin -u root -p"${MDB_ROOT}" shutdown || kill "$pid"
wait "$pid" 2>/dev/null || true

echo "[INFO] Starting MariaDB..."
exec mysqld --user=mysql --bind-address=0.0.0.0 --port=3306
