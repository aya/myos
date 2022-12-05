ENV_VARS                                  += IPFS_API_HTTPHEADERS_ACA_ORIGIN IPFS_DAEMON_ARGS IPFS_PROFILE IPFS_SERVICE_5001_TAGS IPFS_SERVICE_8080_TAGS IPFS_VERSION
IPFS_API_HTTPHEADERS_ACA_ORIGIN           ?= ["https://ipfs.$(APP_DOMAIN)","http://ipfs.localhost:8080"]
IPFS_PROFILE                              ?= $(if $(filter-out amd64 x86_64,$(MACHINE)),lowpower,server)
IPFS_SERVICE_5001_TAGS                    ?= urlprefix-ipfs.$(APP_DOMAIN)/api
IPFS_SERVICE_8080_CHECK_HTTP              ?= /ipfs/QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn
IPFS_SERVICE_8080_TAGS                    ?= urlprefix-ipfs.$(APP_DOMAIN)/,urlprefix-*.ipfs.$(APP_DOMAIN),urlprefix-ipns.$(APP_DOMAIN)/,urlprefix-*.ipns.$(APP_DOMAIN)/
IPFS_UFW_DOCKER                           ?= 4001/tcp 4001/udp 8080
IPFS_VERSION                              ?= 0.16.0

.PHONY: bootstrap-stack-ipfs
bootstrap-stack-ipfs: ~/.ipfs setup-sysctl

~/.ipfs:
	mkdir -p ~/.ipfs
