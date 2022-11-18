CMDARGS                         += node-exec stack-node-exec node-exec:% node-exec@% node-run node-run:% node-run@%
node                            ?= $(patsubst stack/%,%,$(patsubst %.yml,%,$(wildcard stack/node/*.yml)))
ENV_VARS                        += DOCKER_HOST_IFACE DOCKER_HOST_INET4 DOCKER_INTERNAL_DOCKER_HOST
SETUP_LETSENCRYPT               ?=

# target bootstrap-stack-node: Fire node-certbot node-ssl-certs
.PHONY: bootstrap-stack-node
bootstrap-stack-node: $(if $(SETUP_LETSENCRYPT),node-certbot$(if $(DEBUG),-staging)) node-ssl-certs

# target node: Fire stack-node-up
.PHONY: node
node: stack-node-up

# target node-%; Fire target stack-node-%
.PHONY: node-%
node-%: stack-node-%;

# target node-ssl-certs: Create invalid ${DOMAIN} certificate files with openssl
.PHONY: node-ssl-certs
node-ssl-certs:
	docker run --rm --mount source=$(NODE_DOCKER_VOLUME),target=/certs alpine \
	 [ -f /certs/live/$(DOMAIN)/fullchain.pem -a -f /certs/live/$(DOMAIN)/privkey.pem ] \
	|| $(RUN) docker run --rm \
	 -e DOMAIN=$(DOMAIN) \
	 --mount source=$(NODE_DOCKER_VOLUME),target=/certs \
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

# target node-certbot: Create ${DOMAIN} certificate files with letsencrypt
.PHONY: node-certbot
node-certbot: node-docker-build-certbot
	docker run --rm --mount source=$(NODE_DOCKER_VOLUME),target=/certs alpine \
	 [ -f /certs/live/$(DOMAIN)/cert.pem -a -f /certs/live/$(DOMAIN)/privkey.pem ] \
	|| $(RUN) docker run --rm \
	 --mount source=$(NODE_DOCKER_VOLUME),target=/etc/letsencrypt/ \
	 --mount source=$(NODE_DOCKER_VOLUME),target=/var/log/letsencrypt/ \
	 -e DOMAIN=$(DOMAIN) \
	 --network host \
	 node/certbot \
	  --non-interactive --agree-tos --email hostmaster@${DOMAIN} certonly \
	  --preferred-challenges dns --authenticator dns-standalone \
	  --dns-standalone-address=0.0.0.0 \
	  --dns-standalone-port=53 \
	  -d ${DOMAIN} \
	  -d *.${DOMAIN}

# target node-certbot-certificates: List letsencrypt certificates
.PHONY: node-certbot-certificates
node-certbot-certificates: node-docker-build-certbot
	docker run --rm --mount source=$(NODE_DOCKER_VOLUME),target=/etc/letsencrypt/ node/certbot certificates

# target node-certbot-renew: Renew letsencrypt certificates
.PHONY: node-certbot-renew
node-certbot-renew: node-docker-build-certbot
	docker run --rm --mount source=$(NODE_DOCKER_VOLUME),target=/etc/letsencrypt/ --network host node/certbot renew

# target node-certbot-staging: Create staging ${DOMAIN} certificate files with letsencrypt
.PHONY: node-certbot-staging
node-certbot-staging: node-docker-build-certbot
	docker run --rm --mount source=$(NODE_DOCKER_VOLUME),target=/certs alpine \
	 [ -f /certs/live/$(DOMAIN)/cert.pem -a -f /certs/live/$(DOMAIN)/privkey.pem ] \
	|| $(RUN) docker run --rm \
	 --mount source=$(NODE_DOCKER_VOLUME),target=/etc/letsencrypt/ \
	 --mount source=$(NODE_DOCKER_VOLUME),target=/var/log/letsencrypt/ \
	 -e DOMAIN=$(DOMAIN) \
	 --network host \
	 node/certbot \
	  --non-interactive --agree-tos --email hostmaster@${DOMAIN} certonly \
	  --preferred-challenges dns --authenticator dns-standalone \
	  --dns-standalone-address=0.0.0.0 \
	  --dns-standalone-port=53 \
	  --staging \
	  -d ${DOMAIN} \
	  -d *.${DOMAIN}

# target node-docker-build-%: Build % docker
.PHONY: node-docker-build-%
node-docker-build-%:
	$(call docker-build,docker/$*,node/$*:$(DOCKER_IMAGE_TAG))

# target node-docker-rebuild-%: Rebuild % docker
.PHONY: node-docker-rebuild-%
node-docker-rebuild-%:
	$(call make,node-docker-build-$* DOCKER_BUILD_CACHE=false)

