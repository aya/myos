FROM alpine:3.11 as dist
LABEL maintainer "yann.autissier@gmail.com"
ARG DOCKER_BUILD_DIR
ARG VERSION_PDNS_REC=4.2.1
ARG VERSION_PDNS_AUTH=4.2.1
ARG VERSION_PDNS_DNSDIST=1.4.0

RUN apk upgrade --no-cache \
 && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        bison \
        boost-dev \
        boost-program_options \
        boost-serialization \
        build-base \
        curl \
        curl-dev \
        file \
        flex \
        g++ \
        git \
        py-virtualenv \
        libedit-dev \
        libressl-dev \
        libstdc++ \
        libtool \
        lua-dev \
        make \
        musl \
        ragel \
 && git clone https://github.com/PowerDNS/pdns \
 && cd pdns \
 && git checkout tags/auth-${VERSION_PDNS_AUTH} -b auth-${VERSION_PDNS_AUTH} \
 && autoreconf -vi \
 && ./configure --enable-static --disable-systemd --without-systemd --with-modules="" \
 && make install clean \
 && git checkout tags/rec-${VERSION_PDNS_REC} -b rec-${VERSION_PDNS_REC} \
 && cd pdns/recursordist \
 && autoreconf -vi \
 && ./configure --enable-static --disable-systemd --without-systemd \
 && make install clean \
 && cd ../.. \
 && git checkout tags/dnsdist-${VERSION_PDNS_DNSDIST} -b dnsdist-${VERSION_PDNS_DNSDIST} \
 && cd pdns/dnsdistdist \
 && autoreconf -vi \
 && ./configure --enable-static --disable-systemd --without-systemd \
 && make install clean \
 && cd ../../.. \
 && rm -fr pdns \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | xargs -r apk info --installed \
      | sort -u \
  )" \
 && apk del .build-deps \
 && apk add --no-cache --virtual .run-deps $runDeps \
        lua

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 53/udp 53/tcp

FROM dist as local
ARG DOCKER_BUILD_DIR

FROM local as debug
ARG DOCKER_BUILD_DIR

FROM local as tests
ARG DOCKER_BUILD_DIR

FROM tests as preprod
ARG DOCKER_BUILD_DIR

FROM preprod as prod
ARG DOCKER_BUILD_DIR
