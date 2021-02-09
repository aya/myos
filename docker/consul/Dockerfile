FROM consul:1.6.1 as dist
ARG DOCKER_BUILD_DIR

LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>

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
