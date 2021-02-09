FROM phabricator/phabricator:latest as dist
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR

RUN { \
        echo 'mysqli.allow_local_infile = 0'; \
    } > /usr/local/etc/php/conf.d/mysql.ini

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
