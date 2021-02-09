FROM php:7.2-fpm-alpine as dist
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR

ARG AMQP_VERSION=stable
ARG AST_VERSION=stable
ARG APCU_VERSION=stable
ARG BLACKFIRE_VERSION=1.34.3
ARG CACHETOOL_VERSION=4.0.1
ARG DS_VERSION=stable
ARG EVENT_VERSION=stable
ARG IGBINARY_VERSION=stable
ARG IMAGICK_VERSION=stable
ARG GEOIP_VERSION=beta
ARG GRPC_VERSION=stable
ARG MCRYPT_VERSION=stable
ARG MEMCACHE_VERSION=4.0.1-php73
ARG MEMCACHED_VERSION=stable
ARG MONGODB_VERSION=stable
ARG NEWRELIC_VERSION=9.11.0.267
ARG OAUTH_VERSION=stable
ARG RAR_VERSION=stable
ARG REDIS_VERSION=stable
ARG SNUFFLEUPAGUS_VERSION=0.5.1
ARG UUID_VERSION=stable
ARG XDEBUG_VERSION=stable
ARG XHPROF_VERSION=2.2.0
ARG YAML_VERSION=stable

RUN apk --no-cache upgrade \
 && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        aspell-dev \
        bison \
        bzip2-dev \
        curl-dev \
        enchant2-dev \
        flex \
        freetype-dev \
        gawk \
        geoip-dev \
        gettext-dev \
        gmp-dev \
        icu-dev \
        imagemagick-dev \
        imap-dev \
        libevent-dev \
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
        patch \
        postgresql-dev \
        pcre-dev \
        rabbitmq-c-dev \
        yaml-dev \
        zlib-dev \
 # blackfire \
 && wget https://packages.blackfire.io/binaries/blackfire-php/${BLACKFIRE_VERSION}/blackfire-php-alpine_amd64-php-$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;").so -O $(php -r "echo ini_get('extension_dir');")/blackfire.so \
 # enchant \
 && docker-php-source extract \
 && wget "https://git.alpinelinux.org/aports/plain/community/php7/enchant-2.patch?id=3f8d7d2e5e558a975f79b6470423b32e01c0bfbc" -O /usr/src/php-enchant-2.patch \
 && cd /usr/src/php && patch -p1 < ../php-enchant-2.patch \
 # gd \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
 # memcache \
 && wget https://github.com/websupport-sk/pecl-memcache/archive/v${MEMCACHE_VERSION}.tar.gz -O /tmp/memcache-${MEMCACHE_VERSION}.tar.gz \
 && mkdir -p /tmp/memcache-${MEMCACHE_VERSION} \
 && tar xzf /tmp/memcache-${MEMCACHE_VERSION}.tar.gz -C /tmp/memcache-${MEMCACHE_VERSION} --strip-components=1 \
 # https://github.com/websupport-sk/pecl-memcache/pull/39 \
 && sed -i '399s/);/, char *);/' /tmp/memcache-${MEMCACHE_VERSION}/php7/memcache_pool.h \
 # https://github.com/websupport-sk/pecl-memcache/pull/40 \
 && sed -i '47i#if PHP_VERSION_ID < 70200\n    register size_t newlen;\n#endif' /tmp/memcache-${MEMCACHE_VERSION}/php7/memcache_pool.c \
 # newrelic \
 && wget https://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz -O /tmp/newrelic-${NEWRELIC_VERSION}.tar.gz \
 && mkdir -p /tmp/newrelic-${NEWRELIC_VERSION} \
 && tar xzf /tmp/newrelic-${NEWRELIC_VERSION}.tar.gz -C /tmp/newrelic-${NEWRELIC_VERSION} --strip-components=1 \
 && mv /tmp/newrelic-${NEWRELIC_VERSION}/agent/x64/newrelic-20170718.so $(php -r "echo ini_get('extension_dir');")/newrelic.so \
 # snuffleupagus \
 && wget https://github.com/jvoisin/snuffleupagus/archive/v${SNUFFLEUPAGUS_VERSION}.tar.gz -O /tmp/snuffleupagus-${SNUFFLEUPAGUS_VERSION}.tar.gz \
 && mkdir -p /tmp/snuffleupagus-${SNUFFLEUPAGUS_VERSION} \
 && tar xzf /tmp/snuffleupagus-${SNUFFLEUPAGUS_VERSION}.tar.gz -C /tmp/snuffleupagus-${SNUFFLEUPAGUS_VERSION} --strip-components=1 \
 && docker-php-ext-configure /tmp/snuffleupagus-${SNUFFLEUPAGUS_VERSION}/src --prefix=/usr --enable-snuffleupagus \
 # xhprof \
 && wget https://github.com/longxinH/xhprof/archive/v${XHPROF_VERSION}.tar.gz -O /tmp/xhprof-${XHPROF_VERSION}.tar.gz \
 && mkdir -p /tmp/xhprof-${XHPROF_VERSION} \
 && tar xzf /tmp/xhprof-${XHPROF_VERSION}.tar.gz -C /tmp/xhprof-${XHPROF_VERSION} --strip-components=1 \
 && docker-php-ext-configure /tmp/xhprof-${XHPROF_VERSION}/extension --with-php-config=/usr/local/bin/php-config \
 && docker-php-ext-install -j$(nproc) \
        bcmath \
        bz2 \
        calendar \
        dba \
        enchant \
        exif \
        gd \
        gettext \
        gmp \
        imap \
        intl \
        ldap \
        /tmp/memcache-${MEMCACHE_VERSION} \
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
        /tmp/xhprof-${XHPROF_VERSION}/extension \
        xmlrpc \
        xsl \
        zip \
        # docker-php-ext-install fails after snuffleupagus is enabled
        /tmp/snuffleupagus-${SNUFFLEUPAGUS_VERSION}/src \
 && docker-php-source delete \
 && rm /usr/local/etc/php/conf.d/docker-php-ext-* \
 && rm -rf /tmp/memcache-* \
 && rm -rf /tmp/newrelic-* \
 && rm -rf /tmp/snuffleupagus-* \
 && rm -rf /tmp/xhprof-* \
 && pecl install amqp-${AMQP_VERSION} \
 && pecl install apcu-${APCU_VERSION} \
 && pecl install ast-${AST_VERSION} \
 && pecl install ds-${DS_VERSION} \
 && pecl install event-${EVENT_VERSION} \
 && pecl install geoip-${GEOIP_VERSION} \
 && pecl install grpc-${GRPC_VERSION} \
 && pecl install igbinary-${IGBINARY_VERSION} \
 && pecl install imagick-${IMAGICK_VERSION} \
 && pecl install memcached-${MEMCACHED_VERSION} \
 && pecl install mongodb-${MONGODB_VERSION} \
 && pecl install oauth-${OAUTH_VERSION} \
 && pecl install rar-${RAR_VERSION} \
 && pecl install redis-${REDIS_VERSION} \
 && echo |pecl install uuid-${UUID_VERSION} \
 && echo |pecl install mcrypt-${MCRYPT_VERSION} \
 && pecl install xdebug-${XDEBUG_VERSION} \
 && pecl install yaml-${YAML_VERSION} \
 && pecl clear-cache \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | xargs -r apk info --installed \
      | sort -u \
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

# builtin modules : Core ctype curl date dom fileinfo filter ftp hash iconv json libxml mbstring mysqlnd openssl pcre PDO pdo_sqlite Phar posix readline Reflection session SimpleXML SPL sqlite3 standard tokenizer xml xmlreader xmlwriter zlib
# available modules : amqp apcu ast bcmath blackfire bz2 calendar dba ds enchant event exif gd geoip gmp grpc igbinary imap imagick intl ldap mcrypt memcache memcached mongodb mysqli newrelic oauth opcache pcntl pdo_mysql pdo_pgsql pgsql pspell rar redis shmop snmp snuffleupagus soap sockets sysvmsg sysvsem sysvshm xhprof uuid wddx xdebug xhprof xmlrpc xsl yaml zip
ARG PHP_EXT_ENABLE="amqp apcu bcmath bz2 calendar gd geoip imagick intl mcrypt memcached mysqli oauth opcache pdo_mysql redis soap sockets uuid yaml zip"
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
