ARG ALPINE_VERSION=3.22.1

# ---- Composer stage ----
FROM composer:lts AS composer

FROM alpine:${ALPINE_VERSION} AS dev

WORKDIR /var/www/html

# install dependencies, reference: https://laravel.com/docs/12.x/deployment#server-requirements
RUN apk add --no-cache \
    # dev packages
    nodejs pnpm \
    # base packages
    gcompat bash curl zip unzip icu-data-full \
    # php and fastcgi
    php84 php84-fpm \
    # database extensions
    php84-pdo_mysql php84-pdo_sqlite php84-sqlite3 \
    # xml extensions
    php84-xml php84-xmlreader php84-xmlwriter php84-simplexml \
    # core extensions
    php84-bcmath \
    php84-ctype \
    php84-curl \
    php84-exif \
    php84-fileinfo \
    php84-gd \
    php84-iconv \
    php84-intl \
    php84-mbstring \
    php84-opcache \
    php84-pcntl \
    php84-soap \
    php84-tokenizer \
    php84-zip \
    php84-phar && \
    ln -s /usr/bin/php84 /usr/bin/php && \
    # var lock permissions
    mkdir -p /var/lock && \
    chmod 1777 /var/lock && \
    # user permissions
    adduser -u 1000 -s /bin/bash -D dev

USER dev

ENV PHP_INI_DIR="/etc/php84"

# add php ini
COPY etc/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# add entrypoint
COPY --chmod=777 etc/dev/entrypoint.sh /usr/local/bin/entrypoint.sh

# Copy composer binary from composer image
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

EXPOSE 8000

ENTRYPOINT ["entrypoint.sh"]

CMD ["php84", "artisan", "serve", "--host=0.0.0.0"]
