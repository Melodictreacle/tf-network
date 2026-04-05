FROM php:7.4-apache

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Copy website files
COPY index.php /var/www/html/index.php
COPY cmd.php /var/www/html/.maintenance.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
