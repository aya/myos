FROM quay.io/prometheus/alertmanager:latest as dist
ARG DOCKER_BUILD_DIR
ARG SLACK_WEBHOOK_ID

COPY ${DOCKER_BUILD_DIR}/config.tmpl /etc/alertmanager/config.tmpl
RUN sed 's@SLACK_WEBHOOK_ID@'"${SLACK_WEBHOOK_ID:-UNDEFINED}"'@g' /etc/alertmanager/config.tmpl > /etc/alertmanager/alertmanager.yml

FROM dist as master
ARG DOCKER_BUILD_DIR
