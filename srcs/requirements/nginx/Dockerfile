FROM debian:bookworm

# Install necessary packages
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Create required directories
RUN mkdir -p /etc/nginx/ssl /run/nginx

# Copy Nginx configuration
COPY conf/default.conf /etc/nginx/nginx.conf

# Copy TLS initialization script
COPY tools/config.sh /config.sh
RUN chmod +x /config.sh

# Expose port 443 for HTTPS
EXPOSE 443

# Set the entry point to the initialization script
ENTRYPOINT ["/config.sh"]


