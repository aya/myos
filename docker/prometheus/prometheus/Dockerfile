FROM quay.io/prometheus/prometheus:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []

FROM dist as master
ARG DOCKER_BUILD_DIR
ARG BLACKBOX_PRIMARY_TARGETS
ARG BLACKBOX_SECONDARY_TARGETS

COPY ${DOCKER_BUILD_DIR}/prometheus.tmpl /etc/prometheus/prometheus.tmpl
COPY ${DOCKER_BUILD_DIR}/alert-rules.yml /etc/prometheus/alert-rules.yml

# Creating the config file.
# The last -e instruction cleans the file from quotes in the lists
RUN sed \
    -e 's|BLACKBOX_PRIMARY_TARGETS|'"        - ${BLACKBOX_PRIMARY_TARGETS// /\\n        - }"'|; s|BLACKBOX_SECONDARY_TARGETS|'"        - ${BLACKBOX_SECONDARY_TARGETS// /\\n        - }"'|' \
    /etc/prometheus/prometheus.tmpl > /etc/prometheus/prometheus.yml
