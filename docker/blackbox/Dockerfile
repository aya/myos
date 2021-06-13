FROM quay.io/prometheus/blackbox-exporter:latest as dist
ARG DOCKER_BUILD_DIR

COPY ${DOCKER_BUILD_DIR}/config.yml /etc/blackbox_exporter/config.yml

FROM dist as master
ARG DOCKER_BUILD_DIR
