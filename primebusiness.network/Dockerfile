FROM php:8.2-apache-bookworm

# Enable common Apache modules (cPanel default behavior)
RUN a2enmod rewrite headers expires

# PHP opcache for static-heavy site performance
RUN docker-php-ext-install opcache

# Copy site contents (HTML, PHP, assets)
WORKDIR /var/www/html
COPY . /var/www/html/

# Ownership for Apache
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
