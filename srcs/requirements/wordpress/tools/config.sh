#!/bin/bash

set -e

# LECTURE DES SECRETS
if [ -f /run/secrets/db_password ]; then
    MDB_PWD=$(cat /run/secrets/db_password)
else
    echo "[ERROR] Secret db_password not found!"
    exit 1
fi

if [ -f /run/secrets/wp_admin_password ]; then
    WP_ADMIN_PWD=$(cat /run/secrets/wp_admin_password)
else
    echo "[ERROR] Secret wp_admin_password not found!"
    exit 1
fi

if [ -f /run/secrets/wp_user_password ]; then
    WP_USER_PWD=$(cat /run/secrets/wp_user_password)
else
    echo "[ERROR] Secret wp_user_password not found!"
    exit 1
fi

# Attente que la base de données soit prête
echo "[INFO] Waiting for MariaDB to be ready..."
until mysqladmin ping -h"$MDB_HOST" -u"$MDB_USER" -p"$MDB_PWD" --silent 2>/dev/null; do 
    echo "[INFO] Still waiting for MariaDB at $MDB_HOST..."
    sleep 2
done

echo "[INFO] MariaDB is ready!"

# Installation de WordPress si wp-config.php n'existe pas
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "[INFO] Installing WordPress..."

    # Création du fichier de configuration WordPress
    wp config create \
        --dbname="$MDB_NAME" \
        --dbuser="$MDB_USER" \
        --dbpass="$MDB_PWD" \
        --dbhost="$MDB_HOST" \
        --path="/var/www/html" \
        --allow-root
    
    # Installation du core WordPress
    wp core install \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN" \
        --admin_password="$WP_ADMIN_PWD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
    
    # Création d'un utilisateur supplémentaire
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PWD" \
        --role=subscriber \
        --allow-root

    # Configuration des URLs
    wp option update home "$WP_URL" --allow-root 
    wp option update siteurl "$WP_URL" --allow-root

    echo "[INFO] WordPress installation completed!"
else
    echo "[INFO] WordPress already configured"
fi

# Lancement de PHP-FPM
exec "$@"