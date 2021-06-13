FROM braedon/prometheus-es-exporter:0.5.2 AS dist
ARG DOCKER_BUILD_DIR

COPY ${DOCKER_BUILD_DIR}/exporter.cfg /usr/src/app

FROM dist as master
ARG DOCKER_BUILD_DIR
