FROM alpine:latest as dist
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR

ARG S3FS_VERSION=v1.85

# Install s3fs-fuse
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
 && apk add --no-cache --virtual .run-deps $runDeps curl openssl

ARG S3FS_DIR=/srv/s3
ENV S3FS_DIR=${S3FS_DIR}
RUN mkdir -p ${S3FS_DIR}
VOLUME ${S3FS_DIR}

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
ENTRYPOINT /docker-entrypoint.sh

FROM dist as local
ARG DOCKER_BUILD_DIR
ARG UID=0
ARG USER=root
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

FROM local as debug
ARG DOCKER_BUILD_DIR

FROM local as tests
ARG DOCKER_BUILD_DIR

FROM tests as preprod
ARG DOCKER_BUILD_DIR

FROM preprod as prod
ARG DOCKER_BUILD_DIR
