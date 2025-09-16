# ---- Composer stage ----
FROM composer:lts AS composer

# ---- Debian stage ----
FROM debian:stable-slim AS dev

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /var/www/html

# install dependencies, reference: https://laravel.com/docs/12.x/deployment#server-requirements
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
    # dev packages
    ca-certificates sudo xz-utils curl nodejs openssh-client \
    # base packages
    zip unzip \
    # php packages
    php \
    # database extensions
    php-mysql php-sqlite3 \
    # xml extensions
    php-xml \
    # core extensions
    php-bcmath php-curl \
    php-gd \
    php-intl \
    php-mbstring \
    php-soap \
    php-tokenizer \
    php-zip \
    php-cli \
    # install pnpm
    && corepack enable && corepack prepare pnpm@latest --activate \
    # clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # var lock permissions
    && mkdir -p /var/lock \
    && chmod 1777 /var/lock \
    # user creation
    && useradd -u 1000 -ms /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# add entrypoint
COPY --chmod=755 etc/dev/entrypoint.sh /usr/local/bin/entrypoint.sh

# Copy composer binary from composer image
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

USER dev

EXPOSE 8000

ENTRYPOINT ["entrypoint.sh"]

CMD ["php", "artisan", "serve", "--host=0.0.0.0"]
