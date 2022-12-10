ENV_VARS                                  += HOST_ACME_POST_HOOK HOST_ACME_PRE_HOOK
HOST_ACME_DOMAIN_PATH_VALID               ?= $$(echo $${DOMAIN_PATH:-} |awk "'"/^[0-9a-z_\-\.\+\/]+@[0-9a-z_\-\.]+\.[a-z0-9_\-\.\+\/]+$$/"'")
HOST_ACME_POST_HOOK                       ?= [ "$(HOST_ACME_DOMAIN_PATH_VALID)" ] && cp fullchain.cer /host/certs/$${domain}-cert.pem 2>/dev/null && cp $${domain}.key /host/certs/$${domain}-key.pem
