FROM debian:bookworm

# Mise à jour du système
RUN apt-get update && apt-get upgrade -y

# Installation des paquets nécessaires
RUN apt-get install -y \
    wget \
    curl \
    netcat-traditional \
    php \
    php-mysql \
    php-fpm \
    php-cli \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Création des répertoires requis
RUN mkdir -p /run/php /var/www/html

# Ajustement des permissions
RUN chown -R www-data:www-data /run/php

# Téléchargement et installation de WordPress
RUN wget https://wordpress.org/latest.tar.gz -P /var/www/ \
    && tar -xzf /var/www/latest.tar.gz -C /var/www/html --strip-components=1 \
    && rm -f /var/www/latest.tar.gz \
    && chown -R www-data:www-data /var/www/html

# Installation de WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Configuration de PHP-FPM pour écouter sur le port 9000
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

# Redirection des logs vers stdout
RUN ln -sf /dev/stdout /var/log/php8.2-fpm.log

# Copie du script de configuration
COPY tools/config.sh /tools/config.sh
RUN chmod +x /tools/config.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["sh", "/tools/config.sh"]

CMD ["/usr/sbin/php-fpm8.2", "-F"]