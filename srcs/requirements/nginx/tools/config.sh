#!/bin/bash

CERT_PATH="/etc/nginx/ssl/nginx.crt"
KEY_PATH="/etc/nginx/ssl/nginx.key"

# Generate the TLS certificate if it does not exist
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo "[INFO] Generating TLS certificate for $DOMAIN_NAME ..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CERT_PATH" \
        -subj "/C=FR/ST=Normandie/L=LeHavre/O=42/CN=${DOMAIN_NAME}"
fi

echo "[INFO] Starting NGINX on port 443 ..."
exec nginx -g "daemon off;"
