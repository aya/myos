FROM alpine:3.11 as dist
LABEL maintainer "yann.autissier@gmail.com"
ARG DOCKER_BUILD_DIR

ARG S3FS_VERSION=v1.85

# Install s3fs-fuse and sftpserver
RUN apk --no-cache upgrade \
 && apk --no-cache add --virtual .build-deps \
        alpine-sdk \
        automake \
        autoconf \
        curl-dev \
        fuse-dev \
        libressl-dev \
        libgcrypt-dev \
        libxml2-dev \
 && git clone https://github.com/s3fs-fuse/s3fs-fuse \
 && cd s3fs-fuse \
 && git checkout tags/${S3FS_VERSION} -b ${S3FS_VERSION} \
 && ./autogen.sh \
 && ./configure --prefix=/usr/local \
 && make install \
 && cd .. \
 && rm -rf s3fs-fuse \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | xargs -r apk info --installed \
      | sort -u \
  )" \
 && apk del .build-deps \
 && apk add --no-cache --virtual .run-deps $runDeps \
        curl \
        lftp \
        logrotate \
        openssh \
        openssl \
        vsftpd

RUN sed -i 's|/var/log/messages|/var/log/*.log|' /etc/logrotate.conf

RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' \
 && ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ''

COPY ${DOCKER_BUILD_DIR}/lftp-sync.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/lftp-sync.sh

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 21/tcp
EXPOSE 1022/tcp
EXPOSE 65000/tcp
VOLUME ["/var/log"]

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
