FROM alpine:3.20

WORKDIR /src

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk add --no-cache \
        php83 \
        php83-phar \
        php83-openssl \
        php83-mbstring \
        php83-xml \
        php83-tokenizer \
        php83-session \
        php83-dom \
        php83-zip \
        php83-pecl-xdebug \
        composer
RUN ln -sf /usr/bin/php83 /usr/bin/php
RUN composer require nelexa/zip:4.0.2

COPY unzip.php /src/unzip.php

WORKDIR /workspace
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
