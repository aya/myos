FROM httpd:alpine as dist
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR

ARG HTTPD_LOAD_MODULE="env expires headers lbmethod_bybusyness lbmethod_byrequests proxy proxy_balancer proxy_fcgi proxy_http setenvif slotmem_shm reqtimeout rewrite"
ARG HTTPD_CONF_EXTRA="default info mpm vhosts"

RUN sed -E -i \
        -e 's!^#?\s*(LoadModule ('${HTTPD_LOAD_MODULE// /|}')_module modules/mod_('${HTTPD_LOAD_MODULE// /|}').so)\s*!\1!g' \
        -e 's!^#?\s*(Include conf/extra/httpd-('${HTTPD_CONF_EXTRA// /|}').conf)\s*!\1!g' \
        "$HTTPD_PREFIX/conf/httpd.conf"; 

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /
COPY ${DOCKER_BUILD_DIR}/httpd-vhosts.ctmpl /usr/local/apache2/conf/extra/
COPY --from=hashicorp/consul-template:alpine /bin/consul-template /usr/local/bin/

WORKDIR /var/www

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD /usr/local/bin/consul-template -log-level info -consul-addr consul:8500 -template "/usr/local/apache2/conf/extra/httpd-vhosts.ctmpl:/usr/local/apache2/conf/extra/httpd-vhosts.conf" -exec "/usr/local/bin/httpd-foreground"

EXPOSE 80/tcp

FROM dist as local
ARG UID
ARG USER
ENV UID=${UID}
ENV GID=${UID}
ENV USER=${USER}
LABEL com.1001pharmacies.uid=${UID}
LABEL com.1001pharmacies.user=${USER}

FROM local as debug
ARG DOCKER_BUILD_DIR

FROM local as tests
ARG DOCKER_BUILD_DIR

FROM tests as preprod
ARG DOCKER_BUILD_DIR

FROM preprod as prod
ARG DOCKER_BUILD_DIR
