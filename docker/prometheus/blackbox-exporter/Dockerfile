FROM quay.io/prometheus/blackbox-exporter:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>

FROM dist as master
ARG DOCKER_BUILD_DIR

COPY ${DOCKER_BUILD_DIR}/config.yml /etc/blackbox_exporter/config.yml
