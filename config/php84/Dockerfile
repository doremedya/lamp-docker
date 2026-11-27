FROM php:8.4.26-apache

ARG UID=1000
ARG GID=1000

# Gerekli kütüphaneler (GD, Zip, PDO vb.) + Türkçe locale
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpng-dev libjpeg-dev libfreetype6-dev libzip-dev zip unzip locales \
    && sed -i 's/^# *tr_TR.UTF-8/tr_TR.UTF-8/' /etc/locale.gen && locale-gen \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd bcmath mysqli pdo_mysql zip opcache \
    && rm -rf /var/lib/apt/lists/*

# Apache host kullanıcısıyla aynı uid/gid ile çalışsın (bind mount izin sorunu olmasın)
RUN groupmod -o -g ${GID} www-data && usermod -o -u ${UID} -g ${GID} www-data

RUN a2enmod rewrite headers
