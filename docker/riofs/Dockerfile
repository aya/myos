FROM alpine:latest as dist
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR

WORKDIR /usr/src

# Install riofs
RUN apk upgrade --no-cache \
 && apk add --no-cache --virtual .build-deps \
        alpine-sdk \
        autoconf \
        automake \
        bsd-compat-headers \
        curl-dev \
        fuse-dev \
        glib-dev \
        libc-dev \
        libevent-dev \
        libexecinfo-dev \
        libressl-dev \
        libxml2-dev \
        musl-dev \
        shared-mime-info \
 && git clone https://github.com/skoobe/riofs \
 && cd riofs \
 && ./autogen.sh \
 && ./configure --prefix=/usr/local \
 && make \
 && make install \
 && cd .. \
 && rm -rf riofs \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | xargs -r apk info --installed \
      | sort -u \
  )" \
 && apk del .build-deps \
 && apk add --no-cache --virtual .run-deps $runDeps

ENTRYPOINT /usr/local/bin/riofs

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
