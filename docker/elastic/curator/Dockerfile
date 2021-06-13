FROM alpine:latest as dist
ARG DOCKER_BUILD_DIR
ARG CURATOR_VERSION=5.8.3

LABEL maintainer aynic.os <support+docker@asycn.io>

RUN apk --no-cache add \
    bash \
    py-pip \
 && pip install elasticsearch-curator==${CURATOR_VERSION}

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
COPY ${DOCKER_BUILD_DIR}/config.yml /etc/curator/
COPY ${DOCKER_BUILD_DIR}/action.yml /etc/curator/

ENTRYPOINT ["/docker-entrypoint.sh"]

FROM dist as master
ARG DOCKER_BUILD_DIR

# install cronlock
ADD https://raw.github.com/kvz/cronlock/master/cronlock /usr/bin/cronlock
RUN chmod +rx /usr/bin/cronlock

# install ssmtp
RUN apk --no-cache add ssmtp && \
    echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf
