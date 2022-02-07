FROM docker.elastic.co/apm/apm-server-oss:7.4.2 as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

# config
COPY ${DOCKER_BUILD_DIR}/apm-server.yml /usr/share/apm-server/

FROM dist as master
ARG DOCKER_BUILD_DIR
