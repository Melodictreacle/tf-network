FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install Apache + PHP stack for OwnCloud
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 libapache2-mod-php php-mysql php-gd php-curl php-zip \
    php-xml php-mbstring php-intl php-json php-bz2 php-redis \
    bzip2 curl sudo \
    && rm -rf /var/lib/apt/lists/*

# Extract OwnCloud application (CVE-2023-49103 — graphapi info disclosure)
COPY Owncloud/owncloud-complete-20230313.tar.bz2 /tmp/
RUN cd /tmp && tar xjf owncloud-complete-20230313.tar.bz2 \
    && mv owncloud /var/www/ \
    && chown -R www-data:www-data /var/www/owncloud \
    && rm -rf /tmp/*

# Apache config for OwnCloud
RUN printf '<VirtualHost *:80>\n\
  DocumentRoot /var/www/owncloud\n\
  <Directory /var/www/owncloud>\n\
    AllowOverride All\n\
    Require all granted\n\
  </Directory>\n\
</VirtualHost>\n' > /etc/apache2/sites-available/owncloud.conf \
    && a2ensite owncloud && a2dissite 000-default \
    && a2enmod rewrite headers env dir mime

# Create data directory
RUN mkdir -p /var/www/owncloud/data \
    && chown -R www-data:www-data /var/www/owncloud/data

# Startup script — auto-configure DB connection to Host G
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80
CMD ["/bin/bash", "/start.sh"]
