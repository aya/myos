FROM php:5.6-fpm-alpine as dist
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR

ARG AMQP_VERSION=stable
ARG APCU_VERSION=4.0.11
ARG BLACKFIRE_VERSION=1.31.0
ARG CACHETOOL_VERSION=3.2.1
ARG IMAGICK_VERSION=stable
ARG GEOIP_VERSION=stable
ARG MEMCACHE_VERSION=3.0.8
ARG MEMCACHED_VERSION=2.2.0
ARG MONGODB_VERSION=1.6.1
ARG NEWRELIC_VERSION=9.6.1.256
ARG RAR_VERSION=stable
ARG REDIS_VERSION=4.3.0
ARG UUID_VERSION=1.0.4
ARG SUHOSIN_VERSION=0.9.38
ARG TWIG_VERSION=1.35.3
ARG XCACHE_VERSION=3.2.0
ARG XDEBUG_VERSION=2.5.5

RUN apk --no-cache upgrade \
 && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        aspell-dev \
        bison \
        bzip2-dev \
        curl-dev \
        flex \
        freetype-dev \
        gawk \
        geoip-dev \
        gettext-dev \
        gmp-dev \
        icu-dev \
        imagemagick-dev \
        imap-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng-dev \
        libressl-dev \
        libxml2-dev \
        libxslt-dev \
        make \
        net-snmp-dev \
        openldap-dev \
        postgresql-dev \
        python \
        rabbitmq-c-dev \
        zlib-dev \
 && wget https://packages.blackfire.io/binaries/blackfire-php/${BLACKFIRE_VERSION}/blackfire-php-alpine_amd64-php-$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;").so -O $(php -r "echo ini_get('extension_dir');")/blackfire.so \
 && wget https://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz -O /tmp/newrelic-${NEWRELIC_VERSION}.tar.gz \
 && mkdir -p /tmp/newrelic-${NEWRELIC_VERSION} \
 && tar xzf /tmp/newrelic-${NEWRELIC_VERSION}.tar.gz -C /tmp/newrelic-${NEWRELIC_VERSION} --strip-components=1 \
 && rm /tmp/newrelic-${NEWRELIC_VERSION}.tar.gz \
 && mv /tmp/newrelic-${NEWRELIC_VERSION}/agent/x64/newrelic-20131226.so $(php -r "echo ini_get('extension_dir');")/newrelic.so \
 && wget --no-check-certificate https://download.suhosin.org/suhosin-${SUHOSIN_VERSION}.tar.gz -O /tmp/suhosin-${SUHOSIN_VERSION}.tar.gz \
 && mkdir -p /tmp/suhosin-${SUHOSIN_VERSION} \
 && tar xzf /tmp/suhosin-${SUHOSIN_VERSION}.tar.gz -C /tmp/suhosin-${SUHOSIN_VERSION} --strip-components=1 \
 && rm /tmp/suhosin-${SUHOSIN_VERSION}.tar.gz \
 && cd /tmp/suhosin-${SUHOSIN_VERSION} \
 && sed -i '1i#include <sys/file.h>' log.c \
 && wget https://github.com/twigphp/Twig/archive/v${TWIG_VERSION}.tar.gz -O /tmp/twig-${TWIG_VERSION}.tar.gz \
 && mkdir -p /tmp/twig-${TWIG_VERSION} \
 && tar xzf /tmp/twig-${TWIG_VERSION}.tar.gz -C /tmp/twig-${TWIG_VERSION} --strip-components=1 \
 && rm /tmp/twig-${TWIG_VERSION}.tar.gz \
 && wget https://web.archive.org/web/20181118151821if_/http://xcache.lighttpd.net/pub/Releases/${XCACHE_VERSION}/xcache-${XCACHE_VERSION}.tar.gz -O /tmp/xcache-${XCACHE_VERSION}.tar.gz \
 && mkdir -p /tmp/xcache-${XCACHE_VERSION} \
 && tar xzf /tmp/xcache-${XCACHE_VERSION}.tar.gz -C /tmp/xcache-${XCACHE_VERSION} --strip-components=1 \
 && rm /tmp/xcache-${XCACHE_VERSION}.tar.gz \
 && docker-php-ext-configure /tmp/xcache-${XCACHE_VERSION} --enable-xcache --enable-xcache-constant --enable-xcache-optimizer --enable-xcache-coverager \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
 && docker-php-ext-install -j$(nproc) \
        /tmp/suhosin-${SUHOSIN_VERSION} \
        /tmp/twig-${TWIG_VERSION}/ext/twig \
        /tmp/xcache-${XCACHE_VERSION} \
        bcmath \
        bz2 \
        calendar \
        dba \
        exif \
        gd \
        gettext \
        gmp \
        imap \
        intl \
        ldap \
        mcrypt \
        mysql \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        pspell \
        shmop \
        snmp \
        soap \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        xmlrpc \
        xsl \
        zip \
 && rm /usr/local/etc/php/conf.d/docker-php-ext-* \
 && rm -rf /tmp/newrelic-* \
 && rm -rf /tmp/suhosin-* \
 && rm -rf /tmp/twig-* \
 && rm -rf /tmp/xcache-* \
 && pecl install amqp-${AMQP_VERSION} \
 && pecl install apcu-${APCU_VERSION} \
 && pecl install geoip-${GEOIP_VERSION} \
 && pecl install imagick-${IMAGICK_VERSION} \
 && pecl install memcache-${MEMCACHE_VERSION} \
 && pecl install memcached-${MEMCACHED_VERSION} \
 && pecl install mongodb-${MONGODB_VERSION} \
 && pecl install rar-${RAR_VERSION} \
 && pecl install redis-${REDIS_VERSION} \
 && echo |pecl install uuid-${UUID_VERSION} \
 && pecl install xdebug-${XDEBUG_VERSION} \
 && pecl clear-cache \
 && runDeps="$( scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
                | tr ',' '\n' \
                | sort -u \
                | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
            )" \
 && apk del .build-deps \
 && apk add --no-cache --virtual .run-deps $runDeps

RUN wget http://gordalina.github.io/cachetool/downloads/cachetool-${CACHETOOL_VERSION}.phar -O /usr/local/bin/cachetool \
 && chmod +x /usr/local/bin/cachetool \
 && echo -e "\
adapter: fastcgi \n\
fastcgi: 127.0.0.1:9000 \n\
" > /etc/cachetool.yml

RUN mkdir -p /etc/ssh && echo -e "\
Host * \n\
  Compression yes \n\
" >> /etc/ssh/ssh_config

RUN apk add --no-cache \
        bash \
        bzip2 \
        coreutils \
        gettext \
        git \
        imagemagick \
        lftp \
        mailx \
        make \
        mysql-client \
        nano \
        openssh-client \
        ssmtp \
        vim

# Iconv fix: https://github.com/docker-library/php/issues/240#issuecomment-305038173
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ gnu-libiconv
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

# enable php modules
# available modules : amqp apcu bcmath blackfire bz2 calendar curl dba exif gettext gd geoip gmp imap imagick intl json ldap mbstring mcrypt memcache memcached mongodb mysql mysqli newrelic opcache pcntl pdo_mysql pdo_pgsql pgsql pspell rar redis shmop simplexml snmp soap sockets suhosin sysvmsg sysvsem sysvshm tokenizer twig uuid xcache xdebug xmlrpc xsl zip
# fix: disabled memcache to avoid relocation errors
ARG PHP_EXT_ENABLE="amqp apcu bcmath blackfire bz2 calendar gd geoip imagick intl mcrypt memcached mysql mysqli opcache pdo_mysql redis soap sockets twig uuid zip"
RUN docker-php-ext-enable ${PHP_EXT_ENABLE}

# copy *.ini
COPY ${DOCKER_BUILD_DIR}/*.ini /usr/local/etc/php/conf.d/
COPY ${DOCKER_BUILD_DIR}/php-fpm-*.conf /usr/local/etc/php-fpm.d/

# custom php config
ARG PHP_INI_CONFIG
RUN echo -e ${PHP_INI_CONFIG// /\\n} >> /usr/local/etc/php/conf.d/config.ini

# custom php cli
ARG PHP_CLI_CONFIG="apc.enable_cli=0 max_execution_time=-1 memory_limit=-1 opcache.enable_cli=0 xdebug.default_enable=0"
RUN echo '#!/usr/bin/env sh' > /usr/local/bin/php-cli \
 && chmod +x /usr/local/bin/php-cli \
 && echo -e "\
/usr/local/bin/php -d ${PHP_CLI_CONFIG// / -d } \"\$@\"\
" >> /usr/local/bin/php-cli

# install cronlock
ADD https://raw.github.com/kvz/cronlock/master/cronlock /usr/bin/cronlock
RUN chmod +rx /usr/bin/cronlock

# config ssmtp
RUN echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf

# https://bugs.php.net/bug.php?id=71880
ENV LOG_STREAM="/tmp/stdout"
RUN mkfifo $LOG_STREAM && chmod 777 $LOG_STREAM

# default www-data homedir to /var/www for crontabs
RUN sed -i 's|/home/www-data|/var/www|' /etc/passwd
WORKDIR /var/www

# redirect LOG_STREAM to stdout and start php-fpm with environment variables from .env
CMD [ "sh", "-c", "(exec 3<>$LOG_STREAM; cat <&3 >&1 & IFS=$'\n'; exec env $(cat .env 2>/dev/null) php-fpm)" ]

FROM dist as local
ARG UID
ARG USER
ENV UID=${UID}
ENV GID=${UID}
ENV USER=${USER}
LABEL com.1001pharmacies.uid=${UID}
LABEL com.1001pharmacies.user=${USER}

# If we provide a specific UID
RUN let $UID >/dev/null 2>&1 \
# Remove user with $UID if it is not our $USER
 && if [ "$(getent passwd $UID |awk 'BEGIN {FS=":"} {print $1}')" != "$USER" ]; then \
      sed -i '/^'$(getent passwd $UID |awk 'BEGIN {FS=":"} {print $1}')':x:'$UID':/d' /etc/passwd; \
      sed -i '/^'$(getent group $GID |awk 'BEGIN {FS=":"} {print $1}')':x:'$GID':/d' /etc/group; \
    fi \
# Force $UID if our $USER already exists
 && sed -i 's/^'$USER':x:[0-9]\+:[0-9]\+:/'$USER':x:'$UID':'$GID':/' /etc/passwd \
 && sed -i 's/^'$USER':x:[0-9]\+:/'$USER':x:'$GID':/' /etc/group \
# Create $USER if it does not exist
 && if [ "$(getent passwd $UID)" = "" ]; then \
      echo "$USER:x:$UID:$GID::/home/$USER:/bin/false" >> /etc/passwd; \
      echo "$USER:!:$(($(date +%s) / 60 / 60 / 24)):0:99999:7:::" >> /etc/shadow; \
      echo "$USER:x:$GID:" >> /etc/group; \
    fi \
 && mkdir -p /home/$USER \
 && chown $UID:$GID /home/$USER \
 || true

RUN chown -R $USER /usr/local/etc/php/conf.d/

USER $USER

RUN mkdir -p ~/.ssh \
 && ssh-keyscan -t rsa -H github.com >> ~/.ssh/known_hosts

FROM local as debug
ARG DOCKER_BUILD_DIR

FROM local as tests
ARG DOCKER_BUILD_DIR

FROM tests as preprod
ARG DOCKER_BUILD_DIR

FROM preprod as prod
ARG DOCKER_BUILD_DIR
