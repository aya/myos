##
# NODE

# target node-ssl-certs: Create ${DOMAIN}.key.pem and ${DOMAIN}.crt.pem files
.PHONY: node-ssl-certs
node-ssl-certs:
	docker run --rm --mount source=$(COMPOSE_PROJECT_NAME_NODE)_ssl-certs,target=/certs alpine [ -f /certs/$(DOMAIN).crt.pem -a -f /certs/$(DOMAIN).key.pem ] \
	 || $(RUN) docker run --rm -e DOMAIN=$(DOMAIN) --mount source=$(COMPOSE_PROJECT_NAME_NODE)_ssl-certs,target=/certs alpine sh -c "\
	   apk --no-cache add openssl \
	   && { [ -f /certs/${DOMAIN}.key.pem ] || openssl genrsa -out /certs/${DOMAIN}.key.pem 2048; } \
	   && openssl req -key /certs/${DOMAIN}.key.pem -out /certs/${DOMAIN}.crt.pem \
		  -addext extendedKeyUsage=serverAuth \
		  -addext subjectAltName=DNS:${DOMAIN} \
		  -subj \"/C=/ST=/L=/O=/CN=${DOMAIN}\" \
		  -x509 -days 365"

