# FROM certbot/certbot:latest as dist
FROM python:3.8-alpine as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

# RUN pip install \
RUN apk --no-cache add --virtual .build-deps \
        build-base \
        libffi-dev \
 && pip install \
        certbot \
        certbot-dns-azure \
#        certbot-dns-bunny \
#        certbot-dns-clouddns \
        certbot-dns-cloudflare \
#        certbot-dns-cloudxns \
        certbot-dns-digitalocean \
#        certbot-dns-dnsmadeeasy \
#        certbot-dns-dnsimple \
#        certbot-dns-gehirn \
#        certbot-dns-godaddy \
        certbot-dns-google \
        certbot-dns-infomaniak \
#        certbot-dns-inwx \
        certbot-dns-ispconfig \
#        certbot-dns-lightsail \
        certbot-dns-linode \
#        certbot-dns-luadns \
#        certbot-dns-njalla \
#        certbot-dns-nsone \
        certbot-dns-ovh \
        certbot-dns-rfc2136 \
        certbot-dns-route53 \
#        certbot-dns-sakuracloud \
        certbot-dns-standalone \
#        certbot-dns-yandexcloud \
#        certbot-ext-auth future \
        certbot-plugin-gandi \
        certbot-s3front \
#        certbot_dns_duckdns \
#        certbot_dns_porkbun \
#        letsencrypt-pritunl \
#        letsencrypt-proxmox \
 && apk del .build-deps

COPY ${DOCKER_BUILD_DIR}/certbot-renew /etc/periodic/daily/
COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]

FROM dist as master
