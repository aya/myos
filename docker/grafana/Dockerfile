FROM grafana/grafana:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR
ARG AWS_ACCESS_KEY
ARG AWS_SECRET_KEY
ARG MYSQL_GRAFANA_USER
ARG MYSQL_GRAFANA_PASSWORD
ARG MYSQL_GRAFANA_DB

COPY ${DOCKER_BUILD_DIR}/config.ini /etc/grafana/config.ini
COPY ${DOCKER_BUILD_DIR}/dashboards /etc/grafana/dashboards
COPY ${DOCKER_BUILD_DIR}/provisioning /etc/grafana/provisioning

USER root

RUN sed 's@AWS_ACCESS_KEY@'"${AWS_ACCESS_KEY:-UNDEFINED}"'@g; s@AWS_SECRET_KEY@'"${AWS_SECRET_KEY:-UNDEFINED}"'@g; s@MYSQL_GRAFANA_USER@'"${MYSQL_GRAFANA_USER:-UNDEFINED}"'@g; s@MYSQL_GRAFANA_PASSWORD@'"${MYSQL_GRAFANA_PASSWORD:-UNDEFINED}"'@g; s@MYSQL_GRAFANA_DB@'"${MYSQL_GRAFANA_DB:-UNDEFINED}"'@g' /etc/grafana/provisioning/datasources/datasources.tmpl > /etc/grafana/provisioning/datasources/datasources.yml

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

USER grafana

ENTRYPOINT ["/docker-entrypoint.sh"]

FROM dist as master
ARG DOCKER_BUILD_DIR
