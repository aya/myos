ENV_VARS                                  += NODE_IPFS_API_HTTPHEADERS_ACA_ORIGIN NODE_IPFS_SERVICE_5001_TAGS NODE_IPFS_SERVICE_8080_TAGS
NODE_IPFS_API_HTTPHEADERS_ACA_ORIGIN      ?= ["https://ipfs.$(DOMAIN)"]
NODE_IPFS_SERVICE_5001_TAGS               ?= urlprefix-ipfs.$(DOMAIN)/api
NODE_IPFS_SERVICE_8080_TAGS               ?= urlprefix-ipfs.$(DOMAIN)/,urlprefix-*.ipfs.$(DOMAIN),urlprefix-ipns.$(DOMAIN)/,urlprefix-*.ipns.$(DOMAIN)/
