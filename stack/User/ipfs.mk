ENV_VARS                                  += USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN USER_IPFS_SERVICE_5001_TAGS USER_IPFS_SERVICE_8080_TAGS
USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN      ?= ["https://ipfs.$(USER_DOMAIN)", "http://ipfs.localhost:8080"]
USER_IPFS_SERVICE_5001_TAGS               ?= urlprefix-ipfs.$(USER_DOMAIN)/user/$(user_domain)/api
USER_IPFS_SERVICE_8080_TAGS               ?= urlprefix-ipfs.$(USER_DOMAIN)/user/$(user_domain),urlprefix-*.ipfs.$(USER_DOMAIN)/user/$(user_domain),urlprefix-ipns.$(USER_DOMAIN)/user/$(user_domain),urlprefix-*.ipns.$(USER_DOMAIN)/user/$(user_domain)
