FROM quay.io/prometheus/blackbox-exporter:latest as dist
ARG DOCKER_BUILD_DIR

COPY ${DOCKER_BUILD_DIR}/config.yml /etc/blackbox_exporter/config.yml

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
