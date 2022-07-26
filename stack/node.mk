node                            ?= node/node node/portainer
ENV_VARS                        += DOCKER_HOST_IFACE DOCKER_HOST_INET4 DOCKER_INTERNAL_DOCKER_HOST IPFS_PROFILE
IPFS_PROFILE                    ?= $(if $(filter-out amd64 x86_64,$(PROCESSOR_ARCHITECTURE)),lowpower,server)

# target bootstrap-stack-node: Fire node-ssl-certs
.PHONY: bootstrap-stack-node
bootstrap-stack-node: docker-network-create-$(DOCKER_NETWORK_PUBLIC) node-ssl-certs

# target node: Fire stack-node-up
.PHONY: node
node: stack-node-up

# target node-%; Fire target stack-node-%
node-%: stack-node-%;

# target node-ssl-certs: Create ${DOMAIN}.key.pem and ${DOMAIN}.crt.pem files
.PHONY: node-ssl-certs
node-ssl-certs:
	docker run --rm --mount source=$(NODE_COMPOSE_PROJECT_NAME)_ssl-certs,target=/certs alpine [ -f /certs/$(DOMAIN).crt.pem -a -f /certs/$(DOMAIN).key.pem ] \
	 || $(RUN) docker run --rm -e DOMAIN=$(DOMAIN) --mount source=$(NODE_COMPOSE_PROJECT_NAME)_ssl-certs,target=/certs alpine sh -c "\
	   apk --no-cache add openssl \
	   && { [ -f /certs/${DOMAIN}.key.pem ] || openssl genrsa -out /certs/${DOMAIN}.key.pem 2048; } \
	   && openssl req -key /certs/${DOMAIN}.key.pem -out /certs/${DOMAIN}.crt.pem \
		  -addext extendedKeyUsage=serverAuth \
		  -addext subjectAltName=DNS:${DOMAIN} \
		  -subj \"/C=/ST=/L=/O=/CN=${DOMAIN}\" \
		  -x509 -days 365"
