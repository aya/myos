FROM nimmis/alpine-apache-php5
ARG DOCKER_BUILD_DIR

RUN apk add --no-cache \
        memcached \
        php5-bz2 \
        php5-enchant \
        php5-gmp \
        php5-imap \
        php5-ldap \
        php5-memcache \
        php5-mssql \
        php5-mysqli \
        php5-opcache \
        php5-pdo \
        php5-pdo_mysql \
        php5-pdo_pgsql \
        php5-pdo_sqlite \
        php5-pspell \
        php5-snmp \
        php5-xcache \
        php5-xmlrpc \
        php5-xsl

COPY ${DOCKER_BUILD_DIR}/apache-php5-config.sh /etc/run_always/51-config-apache
COPY ${DOCKER_BUILD_DIR}/php.ini /etc/php5/
COPY ${DOCKER_BUILD_DIR}/header.php /etc/php5/

RUN mkdir -p /etc/sv/memcached \
 && echo -e '#!/bin/sh\n\nexec 2>&1\nexec chpst -u apache /usr/bin/memcached -s /var/tmp/memcached\n' > /etc/sv/memcached/run \
 && chmod +x /etc/sv/memcached/run \
 && ln -s ../sv/memcached /etc/service/memcached
