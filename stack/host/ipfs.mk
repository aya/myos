ENV_VARS                                  += HOST_IPFS_API_HTTPHEADERS_ACA_ORIGIN HOST_IPFS_SERVICE_5001_TAGS HOST_IPFS_SERVICE_8080_TAGS
HOST_IPFS_API_HTTPHEADERS_ACA_ORIGIN      ?= ["https://ipfs.$(DOMAIN)"]
HOST_IPFS_SERVICE_5001_TAGS               ?= urlprefix-ipfs.$(DOMAIN)/api
HOST_IPFS_SERVICE_8080_TAGS               ?= urlprefix-ipfs.$(DOMAIN)/,urlprefix-*.ipfs.$(DOMAIN),urlprefix-ipns.$(DOMAIN)/,urlprefix-*.ipns.$(DOMAIN)/
HOST_IPFS_UFW_DOCKER                      ?= 4001/tcp 4001/udp 8080
