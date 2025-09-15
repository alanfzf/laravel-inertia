ARG ALPINE_VERSION=3.22.1

# ==================
# VENDOR STAGE
# ==================
FROM composer:lts AS vendor

WORKDIR /composer
COPY . .

RUN composer install \
        --ignore-platform-reqs \
        --no-ansi \
        # --no-dev \
        --no-interaction \
        --no-progress \
        --prefer-dist \
        --optimize-autoloader

# ==================
# NODE MODULES STAGE
# ==================
FROM node:lts-alpine AS node

ENV CI=true

WORKDIR /node
COPY . .
RUN corepack enable pnpm && pnpm i --production && pnpm build

# ==================
# FINAL IMAGE
# ==================
FROM alpine:${ALPINE_VERSION} AS production

WORKDIR /var/www/html

# Copy app source code
COPY . .
COPY --from=vendor /composer/vendor/ /var/www/html/vendor
COPY --from=node /node/public/build /var/www/html/public/build

# install dependencies, reference: https://laravel.com/docs/12.x/deployment#server-requirements
RUN apk add --no-cache \
    # base packages
    gcompat bash curl zip unzip nginx supervisor icu-data-full \
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
    php84-zip && \
    # ==== symlink php =====
    ln -s /usr/bin/php84 /usr/bin/php && \
    chown -R nobody:nobody /var/www/html /run /var/lib/nginx /var/log/nginx

ENV PHP_INI_DIR="/etc/php84"

# configure nginx
COPY etc/nginx.conf /etc/nginx/nginx.conf
COPY etc/conf.d /etc/nginx/conf.d/

# configure fpm & and php
COPY etc/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
COPY etc/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# configure supervisord
COPY etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

USER nobody

EXPOSE 8000

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
