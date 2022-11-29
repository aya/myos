ENV_VARS                                  += USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN USER_IPFS_SERVICE_5001_TAGS USER_IPFS_SERVICE_8080_TAGS
USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN      ?= ["https://ipfs.$(user_domain).$(DOMAIN)"]
USER_IPFS_SERVICE_5001_TAGS               ?= $(if $(filter localhost,$(DOMAIN)),urlprefix-ipfs.$(user_domain).$(DOMAIN)/api/)
USER_IPFS_SERVICE_8080_TAGS               ?= urlprefix-ipfs.$(user_domain).$(DOMAIN)/
