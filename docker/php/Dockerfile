FROM php:8.3-fpm

ARG UID=1000
ARG GID=1000

ARG MAGENTO_PUBLIC_KEY
ARG MAGENTO_PRIVATE_KEY

RUN groupmod -g ${GID} www-data || true
RUN usermod -u ${UID} -g ${GID} www-data || true

ENV COMPOSER_HOME=/var/www/.config/composer

RUN mkdir -p /var/www/.config/composer \
    && chmod -R 775 /var/www/.config \
    && chown -R 33:33 /var/www/.config

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    cron \
    redis-tools \
    netcat-openbsd \
    imagemagick \
    default-mysql-client \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libmagickwand-dev \
    libgmp-dev \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg

RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    exif \
    ftp \
    gd \
    gettext \
    intl \
    mbstring \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    soap \
    sockets \
    xsl \
    zip

RUN pecl install redis imagick \
    && docker-php-ext-enable redis imagick

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY docker/php/php.ini /usr/local/etc/php/conf.d/php.ini

COPY docker/php/job-install-magento.sh /usr/local/bin/job-install-magento.sh

RUN chmod +x /usr/local/bin/job-install-magento.sh

RUN composer config --global --auth http-basic.repo.magento.com \
    ${MAGENTO_PUBLIC_KEY} \
    ${MAGENTO_PRIVATE_KEY}

RUN composer create-project \
    --repository-url=https://repo.magento.com/ \
    magento/project-community-edition .

RUN chown -R 33:33 /var/www/html

CMD ["php-fpm"]