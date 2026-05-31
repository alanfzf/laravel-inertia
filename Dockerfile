# ---- Composer stage ----
FROM composer:lts AS vendor

WORKDIR /composer
COPY . .

RUN composer install \
        --ignore-platform-reqs \
        --no-ansi \
        # --no-dev \
        --no-interaction \
        --no-progress \
        --no-scripts \
        --prefer-dist \
        --optimize-autoloader

# ---- Node stage ----
FROM node:lts-alpine AS node

WORKDIR /node
COPY . .
RUN npm i && npm run build

# ---- Debian stage ----
FROM debian:stable-slim AS prod

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /var/www/html

COPY . .
COPY --from=vendor /composer/vendor vendor
COPY --from=node /node/public/build /var/www/html/public/build

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    # base packages
    zip unzip ca-certificates xz-utils curl nginx \
    # php packages
    php php-fpm \
    # database extensions
    php-mysql php-sqlite3 \
    # xml extensions
    php-xml \
    # cache extensions
    php-redis \
    # core extensions
    php-bcmath php-curl \
    php-gd \
    php-intl \
    php-mbstring \
    php-soap \
    php-tokenizer \
    php-zip \
    php-cli \
    # clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && chown -R nobody:nogroup /var/www/html /run /var/lib/nginx /var/log/nginx

# configure nginx
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/conf.d/ /etc/nginx/conf.d/

# configure fpm and php
COPY docker/php/fpm-pool.conf /etc/php/8.4/fpm/pool.d/www.conf
COPY docker/php/php.ini  /etc/php/8.4/cli/conf.d/99-custom.ini
COPY docker/php/php.ini  /etc/php/8.4/fpm/conf.d/99-custom.ini

EXPOSE 8000

USER nobody

CMD ["sh", "-c", "php-fpm8.4 & nginx"]
