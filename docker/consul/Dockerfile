FROM consul:1.6.1 as dist
ARG DOCKER_BUILD_DIR

LABEL maintainer aynic.os <support+docker@asycn.io>

# install docker
RUN apk add --no-cache bash docker gawk sudo \
 && echo "consul ALL=(root) NOPASSWD: /usr/local/bin/container-list-status" >> /etc/sudoers

# install goss
ADD https://github.com/aelsabbahy/goss/releases/latest/download/goss-linux-amd64 /usr/bin/goss
RUN chmod +rx /usr/bin/goss
COPY ${DOCKER_BUILD_DIR}/goss.yml /tests/goss.yml

COPY ${DOCKER_BUILD_DIR}/container-check-status ${DOCKER_BUILD_DIR}/container-list-status /usr/local/bin/
RUN chmod +rx /usr/local/bin/container-check-status /usr/local/bin/container-list-status

HEALTHCHECK CMD goss -g /tests/goss.yml validate --format tap

FROM dist as master
ARG DOCKER_BUILD_DIR
