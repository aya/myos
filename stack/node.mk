ENV_VARS += DOCKER_HOST_IFACE DOCKER_HOST_INET

# target node: Fire docker-network-create-% for DOCKER_NETWORK_PUBLIC node-openssl stack-node-up
.PHONY: node
node: docker-network-create-$(DOCKER_NETWORK_PUBLIC) node-openssl stack-node-up

# target node-openssl: Create /certs/${DOMAIN}.key.pem and /certs/${DOMAIN}.crt.pem files
.PHONY: node-openssl
node-openssl:
	docker run --rm --mount source=$(COMPOSE_PROJECT_NAME_NODE)_ssl-certs,target=/certs alpine:latest [ -f /certs/$(DOMAIN).crt.pem -a -f /certs/$(DOMAIN).key.pem ] \
	 || docker run --rm -e DOMAIN=$(DOMAIN) --mount source=$(COMPOSE_PROJECT_NAME_NODE)_ssl-certs,target=/certs alpine:latest sh -c "apk --no-cache add openssl \
		   && { [ -f /certs/${DOMAIN}.key.pem ] || openssl genrsa -out /certs/${DOMAIN}.key.pem 2048; } \
	       && openssl req -key /certs/${DOMAIN}.key.pem -out /certs/${DOMAIN}.crt.pem -addext extendedKeyUsage=serverAuth -addext subjectAltName=DNS:${DOMAIN} -subj \"/C=/ST=/L=/O=/CN=${DOMAIN}\" -x509 -days 365"
