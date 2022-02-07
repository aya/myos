FROM phabricator/phabricator:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

RUN { \
        echo 'mysqli.allow_local_infile = 0'; \
    } > /usr/local/etc/php/conf.d/mysql.ini

FROM dist as master
ARG DOCKER_BUILD_DIR
