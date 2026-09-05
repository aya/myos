ENV_VARS                                  += HOST_ACME_POST_HOOK HOST_ACME_PRE_HOOK
HOST_ACME_DOMAIN_PATH_VALID               ?= $$(echo $${DOMAIN_PATH:-} |awk "'"/^[0-9a-z_\-\.+\/]+@[0-9a-z_\-\.]+\.[a-z0-9_\-\.\+\/]+$$/"'")
HOST_ACME_DOMAIN_CERT_MODULUS             ?= $$(openssl x509 -in fullchain.cer -noout -modulus)
HOST_ACME_DOMAIN_KEY_MODULUS              ?= $$(openssl rsa -in $${domain}.key -noout -modulus)
HOST_ACME_POST_HOOK                       ?= [ "$(HOST_ACME_DOMAIN_PATH_VALID)" ] && cp -a fullchain.cer /host/certs/$${domain}-cert.pem 2>/dev/null && [ "$(HOST_ACME_DOMAIN_CERT_MODULUS)" = "$(HOST_ACME_DOMAIN_KEY_MODULUS)" ] && cp -a $${domain}.key /host/certs/$${domain}-key.pem
