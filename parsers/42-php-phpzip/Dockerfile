FROM php:8.3-cli-alpine

WORKDIR /src

RUN apk add --no-cache $PHPIZE_DEPS
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN apk del $PHPIZE_DEPS

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer require nelexa/zip:4.0.2

COPY unzip.php /src/unzip.php

WORKDIR /workspace
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
