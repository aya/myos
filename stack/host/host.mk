ENV_VARS                        += DOCKER_HOST_IFACE DOCKER_HOST_INET4 DOCKER_INTERNAL_DOCKER_HOST
MAKECMDARGS                     += host-exec stack-host-exec host-exec:% host-exec@% host-run host-run:% host-run@%
SETUP_LETSENCRYPT               ?=
host                            ?= host/consul host/fabio host/registrator

# target bootstrap-stack-host: Fire host-certbot host-ssl-certs
.PHONY: bootstrap-stack-host
bootstrap-stack-host: $(if $(SETUP_CERTBOT),host-certbot) host-ssl-certs

# target host: Fire stack-host-up
.PHONY: host
host: stack-host-up

# target host-%; Fire target stack-host-%
.PHONY: host-%
host-%: stack-host-%;

# target host-ssl-certs: Create invalid ${DOMAIN} certificate files with openssl
.PHONY: host-ssl-certs
host-ssl-certs:
	$(RUN) docker run --rm \
	  -e DOMAIN='$(DOMAIN)' \
	  --mount source=$(HOST_DOCKER_VOLUME),target=/host \
	  alpine sh -c "mkdir -p /host/htpasswd && chmod 700 /host/htpasswd \
	    ; mkdir -p /host/certs && chmod 0700 /host/certs \
	    ; [ -f /host/htpasswd/default.htpasswd ] \
	    || echo "default:{PLAIN}$(shell head -c 15 /dev/random |base64)" > /host/htpasswd/default.htpasswd \
	    ; for domain in ${DOMAIN}; do \
	      [ -f /host/live/\$${domain}/fullchain.pem -a -f /host/live/\$${domain}/privkey.pem ] \
	      && openssl x509 -in /host/live/\$${domain}/fullchain.pem -noout -issuer 2>/dev/null |grep -iqv staging \
	      && cp -L /host/live/\$${domain}/fullchain.pem /host/certs/\$${domain}-cert.pem \
	      && cp -L /host/live/\$${domain}/privkey.pem /host/certs/\$${domain}-key.pem \
	      ; if [ ! -f /host/certs/\$${domain}-cert.pem -o ! -f /host/certs/\$${domain}-key.pem ]; then \
	        apk --no-cache add openssl \
	        && { [ -f /host/certs/\$${domain}-priv.pem ] || openssl genrsa -out /host/certs/\$${domain}-key.pem 2048; } \
	        && openssl req -key /host/certs/\$${domain}-key.pem -out /host/certs/\$${domain}-cert.pem \
	         -addext extendedKeyUsage=serverAuth \
	         -addext subjectAltName=DNS:\$${domain},DNS:*.\$${domain} \
	         -subj \"/C=/ST=/L=/O=/CN=\$${domain}\" \
	         -x509 -days 365 \
	      ; fi \
	    ; done \
	  "

# target host-certbot: Create ${DOMAIN} certificate files with letsencrypt
.PHONY: host-certbot
host-certbot: host-docker-build-certbot
	$(foreach domain,$(DOMAIN), \
	  $(RUN) docker run --rm \
	   -e DOMAIN=$(domain) \
	   --mount source=$(HOST_DOCKER_VOLUME),target=/etc/letsencrypt/ \
	   --mount source=$(HOST_DOCKER_VOLUME),target=/var/log/letsencrypt/ \
	   --network host \
	   $(HOST_DOCKER_REPOSITORY)/certbot \
	    --dns-standalone-address=0.0.0.0 \
	    --dns-standalone-port=53 \
	    --non-interactive --agree-tos --email hostmaster@$(domain) certonly \
	    --preferred-challenges dns --authenticator dns-standalone \
	    -d $(domain) \
	    -d *.$(domain) \
	  && \
	) true

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
	$(foreach domain,$(DOMAIN), \
	  $(RUN) docker run --rm \
	   -e DOMAIN=$(domain) \
	   --mount source=$(HOST_DOCKER_VOLUME),target=/etc/letsencrypt/ \
	   --mount source=$(HOST_DOCKER_VOLUME),target=/var/log/letsencrypt/ \
	   --network host \
	   $(HOST_DOCKER_REPOSITORY)/certbot \
	    --dns-standalone-address=0.0.0.0 \
	    --dns-standalone-port=53 \
	    --non-interactive --agree-tos --email hostmaster@$(domain) certonly \
	    --preferred-challenges dns --authenticator dns-standalone \
	    --staging \
	    -d $(domain) \
	    -d *.$(domain) \
	  && \
	) true

# target host-docker-build-%: Build % docker
.PHONY: host-docker-build-%
host-docker-build-%:
	$(call docker-build,docker/$*,host/$*:$(DOCKER_IMAGE_TAG))

# target host-docker-rebuild-%: Rebuild % docker
.PHONY: host-docker-rebuild-%
host-docker-rebuild-%:
	$(call make,host-docker-build-$* DOCKER_BUILD_CACHE=false)
