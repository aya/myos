FROM python:3.11-alpine as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR
ARG CERTBOT_VERSION=1.32.0

# RUN pip install \
RUN apk --no-cache add --virtual .build-deps \
        augeas-dev \
        build-base \
        libffi-dev \
 && pip install \
        acme==$CERTBOT_VERSION \
        certbot==$CERTBOT_VERSION \
#        certbot-apache \
        certbot-dns-azure \
#        certbot-dns-bunny \
        certbot-dns-clouddns \
        certbot-dns-cloudflare \
        certbot-dns-cloudxns \
        certbot-dns-digitalocean \
        certbot-dns-dnsmadeeasy \
        certbot-dns-dnsimple \
#        certbot-dns-gehirn \
        certbot-dns-godaddy \
        certbot-dns-google \
        certbot-dns-infomaniak \
#        certbot-dns-inwx \
        certbot-dns-ispconfig \
        certbot-dns-lightsail \
        certbot-dns-linode \
        certbot-dns-luadns \
        certbot-dns-njalla \
#        certbot-dns-nsone \
        certbot-dns-ovh \
        certbot-dns-rfc2136 \
        certbot-dns-route53 \
#        certbot-dns-sakuracloud \
        certbot-dns-standalone \
        certbot-dns-yandexcloud \
#        certbot-ext-auth future \
        certbot-nginx \
        certbot-plugin-gandi \
        certbot-s3front \
        certbot_dns_duckdns \
        certbot_dns_porkbun \
#        letsencrypt-pritunl \
#        letsencrypt-proxmox \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | xargs -r apk info --installed \
      | sort -u \
  )" \
 && apk del .build-deps \
 && apk add --no-cache --virtual .run-deps $runDeps

COPY ${DOCKER_BUILD_DIR}/certbot-renew /etc/periodic/daily/
COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]

FROM dist as master
