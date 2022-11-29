CMDARGS                         += host-exec stack-host-exec host-exec:% host-exec@% host-run host-run:% host-run@%
host                            ?= $(patsubst stack/%,%,$(patsubst %.yml,%,$(wildcard stack/host/*.yml)))
ENV_VARS                        += DOCKER_HOST_IFACE DOCKER_HOST_INET4 DOCKER_INTERNAL_DOCKER_HOST
SETUP_LETSENCRYPT               ?=

# target bootstrap-stack-host: Fire host-certbot host-ssl-certs
.PHONY: bootstrap-stack-host
bootstrap-stack-host: $(if $(SETUP_LETSENCRYPT),host-certbot$(if $(DEBUG),-staging)) host-ssl-certs

# target host: Fire stack-host-up
.PHONY: host
host: stack-host-up

# target host-%; Fire target stack-host-%
.PHONY: host-%
host-%: stack-host-%;

# target host-ssl-certs: Create invalid ${DOMAIN} certificate files with openssl
.PHONY: host-ssl-certs
host-ssl-certs:
	docker run --rm --mount source=$(HOST_DOCKER_VOLUME),target=/certs alpine \
	 [ -f /certs/live/$(DOMAIN)/fullchain.pem -a -f /certs/live/$(DOMAIN)/privkey.pem ] \
	|| $(RUN) docker run --rm \
	 -e DOMAIN=$(DOMAIN) \
	 --mount source=$(HOST_DOCKER_VOLUME),target=/certs \
	 alpine sh -c "\
	  apk --no-cache add openssl \
	  && mkdir -p /certs/live/${DOMAIN} \
	  && { [ -f /certs/live/${DOMAIN}/privkey.pem ] || openssl genrsa -out /certs/live/${DOMAIN}/privkey.pem 2048; } \
	  && openssl req -key /certs/live/${DOMAIN}/privkey.pem -out /certs/live/${DOMAIN}/cert.pem \
	   -addext extendedKeyUsage=serverAuth \
	   -addext subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN} \
	   -subj \"/C=/ST=/L=/O=/CN=${DOMAIN}\" \
	   -x509 -days 365 \
	  && rm -f /certs/live/${DOMAIN}/fullchain.pem \
	  && ln -s cert.pem /certs/live/${DOMAIN}/fullchain.pem \
	 "

# target host-certbot: Create ${DOMAIN} certificate files with letsencrypt
.PHONY: host-certbot
host-certbot: host-docker-build-certbot
	docker run --rm --mount source=$(HOST_DOCKER_VOLUME),target=/certs alpine \
	 [ -f /certs/live/$(DOMAIN)/cert.pem -a -f /certs/live/$(DOMAIN)/privkey.pem ] \
	|| $(RUN) docker run --rm \
	 --mount source=$(HOST_DOCKER_VOLUME),target=/etc/letsencrypt/ \
	 --mount source=$(HOST_DOCKER_VOLUME),target=/var/log/letsencrypt/ \
	 -e DOMAIN=$(DOMAIN) \
	 --network host \
	 $(HOST_DOCKER_REPOSITORY)/certbot \
	  --non-interactive --agree-tos --email hostmaster@$(DOMAIN) certonly \
	  --preferred-challenges dns --authenticator dns-standalone \
	  --dns-standalone-address=0.0.0.0 \
	  --dns-standalone-port=53 \
	  -d ${DOMAIN} \
	  -d *.${DOMAIN}

# target host-certbot-certificates: List letsencrypt certificates
.PHONY: host-certbot-certificates
host-certbot-certificates: host-docker-build-certbot
	docker run --rm --mount source=$(HOST_DOCKER_VOLUME),target=/etc/letsencrypt/ $(HOST_DOCKER_REPOSITORY)/certbot certificates

# target host-certbot-renew: Renew letsencrypt certificates
.PHONY: host-certbot-renew
host-certbot-renew: host-docker-build-certbot
	docker run --rm --mount source=$(HOST_DOCKER_VOLUME),target=/etc/letsencrypt/ --network host $(HOST_DOCKER_REPOSITORY)/certbot renew

# target host-certbot-staging: Create staging ${DOMAIN} certificate files with letsencrypt
.PHONY: host-certbot-staging
host-certbot-staging: host-docker-build-certbot
	docker run --rm --mount source=$(HOST_DOCKER_VOLUME),target=/certs alpine \
	 [ -f /certs/live/$(DOMAIN)/cert.pem -a -f /certs/live/$(DOMAIN)/privkey.pem ] \
	|| $(RUN) docker run --rm \
	 --mount source=$(HOST_DOCKER_VOLUME),target=/etc/letsencrypt/ \
	 --mount source=$(HOST_DOCKER_VOLUME),target=/var/log/letsencrypt/ \
	 -e DOMAIN=$(DOMAIN) \
	 --network host \
	 $(HOST_DOCKER_REPOSITORY)/certbot \
	  --non-interactive --agree-tos --email hostmaster@$(DOMAIN) certonly \
	  --preferred-challenges dns --authenticator dns-standalone \
	  --dns-standalone-address=0.0.0.0 \
	  --dns-standalone-port=53 \
	  --staging \
	  -d ${DOMAIN} \
	  -d *.${DOMAIN}

# target host-docker-build-%: Build % docker
.PHONY: host-docker-build-%
host-docker-build-%:
	$(call docker-build,docker/$*,host/$*:$(DOCKER_IMAGE_TAG))

# target host-docker-rebuild-%: Rebuild % docker
.PHONY: host-docker-rebuild-%
host-docker-rebuild-%:
	$(call make,host-docker-build-$* DOCKER_BUILD_CACHE=false)

