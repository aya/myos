FROM quay.io/prometheus/prometheus:latest as dist
ARG DOCKER_BUILD_DIR
ARG MONITORING_PRIMARY_TARGETS_BLACKBOX
ARG MONITORING_SECONDARY_TARGETS_BLACKBOX

LABEL maintainer aynic.os <support+docker@asycn.io>

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

FROM dist as master
ARG DOCKER_BUILD_DIR
