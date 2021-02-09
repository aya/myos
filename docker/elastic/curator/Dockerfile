FROM alpine:latest as dist
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR

ARG CURATOR_VERSION=5.8.3

RUN apk --no-cache add \
    bash \
    py-pip \
 && pip install elasticsearch-curator==${CURATOR_VERSION}

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
COPY ${DOCKER_BUILD_DIR}/config.yml /etc/curator/
COPY ${DOCKER_BUILD_DIR}/action.yml /etc/curator/

ENTRYPOINT ["/docker-entrypoint.sh"]

FROM dist as local
ARG DOCKER_BUILD_DIR

# install cronlock
ADD https://raw.github.com/kvz/cronlock/master/cronlock /usr/bin/cronlock
RUN chmod +rx /usr/bin/cronlock

# install ssmtp
RUN apk --no-cache add ssmtp && \
    echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf

FROM local as debug
ARG DOCKER_BUILD_DIR

FROM local as tests
ARG DOCKER_BUILD_DIR

FROM tests as preprod
ARG DOCKER_BUILD_DIR

COPY build/curator/cronlock.conf /etc/cronlock.conf
COPY build/curator/ssmtp.conf /etc/ssmtp/ssmtp.conf

FROM preprod as prod
ARG DOCKER_BUILD_DIR
