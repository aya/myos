FROM mysql:5.6.44 as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

# config
COPY ${DOCKER_BUILD_DIR}/conf.d/all.cnf /etc/mysql/conf.d/

# install goss
ADD https://github.com/aelsabbahy/goss/releases/latest/download/goss-linux-amd64 /usr/bin/goss
RUN chmod +rx /usr/bin/goss
COPY ${DOCKER_BUILD_DIR}/goss.yml /tests/goss.yml

HEALTHCHECK CMD goss -g /tests/goss.yml validate --format tap

FROM dist as master
ARG DOCKER_BUILD_DIR

# config
COPY ${DOCKER_BUILD_DIR}/conf.d/master.cnf /etc/mysql/conf.d/
