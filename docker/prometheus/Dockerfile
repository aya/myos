FROM quay.io/prometheus/prometheus:latest as dist
LABEL maintainer "jc.iacono.gm@gmail.com"
ARG DOCKER_BUILD_DIR

ARG MONITORING_PRIMARY_TARGETS_BLACKBOX
ARG MONITORING_SECONDARY_TARGETS_BLACKBOX

COPY ${DOCKER_BUILD_DIR}/prometheus.tmpl /etc/prometheus/prometheus.tmpl
COPY ${DOCKER_BUILD_DIR}/alert-rules.yml /etc/prometheus/alert-rules.yml

# Creating the config file.
# The last -e instruction cleans the file from quotes in the lists
RUN sed \
    -e 's|MONITORING_PRIMARY_TARGETS_BLACKBOX|'"        - ${MONITORING_PRIMARY_TARGETS_BLACKBOX// /\\n        - }"'|; s|MONITORING_SECONDARY_TARGETS_BLACKBOX|'"        - ${MONITORING_SECONDARY_TARGETS_BLACKBOX// /\\n        - }"'|' \
    /etc/prometheus/prometheus.tmpl > /etc/prometheus/prometheus.yml

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []

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
