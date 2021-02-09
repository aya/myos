FROM braedon/prometheus-es-exporter:0.5.2 AS dist
ARG DOCKER_BUILD_DIR

COPY ${DOCKER_BUILD_DIR}/exporter.cfg /usr/src/app

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
