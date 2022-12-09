ENV_VARS                                  += HOST_IPFS_API_HTTPHEADERS_ACA_ORIGIN HOST_IPFS_SERVICE_5001_TAGS HOST_IPFS_SERVICE_8080_TAGS
HOST_IPFS_API_HTTPHEADERS_ACA_ORIGIN      ?= [$(call patsublist,%,"https://%",$(HOST_IPFS_SERVICE_8080_URIS))]
HOST_IPFS_SERVICE_URIS                    ?= $(patsubst %,ipfs.%,$(APP_URIS))
HOST_IPFS_SERVICE_5001_TAGS               ?= $(call urlprefix,api,$(HOST_IPFS_SERVICE_5001_URIS))
HOST_IPFS_SERVICE_5051_URIS               ?= $(HOST_IPFS_SERVICE_URIS)
HOST_IPFS_SERVICE_8080_TAGS               ?= $(call urlprefix,,$(HOST_IPFS_SERVICE_8080_URIS))
HOST_IPFS_SERVICE_8080_URIS               ?= $(patsubst %,ipfs.%,$(APP_URIS)) $(patsubst %,*.ipfs.%,$(APP_URIS)) $(patsubst %,ipns.%,$(APP_URIS)) $(patsubst %,*.ipns.%,$(APP_URIS))
HOST_IPFS_UFW_DOCKER                      ?= 4001/tcp 4001/udp 8080
