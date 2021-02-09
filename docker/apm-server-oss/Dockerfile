FROM docker.elastic.co/apm/apm-server-oss:7.4.2 as dist
ARG DOCKER_BUILD_DIR

LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>

# config
COPY ${DOCKER_BUILD_DIR}/apm-server.yml /usr/share/apm-server/

FROM dist as local
ARG DOCKER_BUILD_DIR
