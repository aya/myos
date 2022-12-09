ENV_VARS                                  += USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN USER_IPFS_SERVICE_5001_TAGS USER_IPFS_SERVICE_8080_TAGS
USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN      ?= [$(call patsublist,%,"https://%",$(USER_IPFS_SERVICE_8080_URIS))]
USER_IPFS_SERVICE_URIS                    ?= $(patsubst %,ipfs.%,$(patsubst %,$(RESU).%,$(DOMAIN))/)
USER_IPFS_SERVICE_5001_TAGS               ?= $(filter %.localhost/api,$(call urlprefix,api,$(USER_IPFS_SERVICE_5001_URIS)))
USER_IPFS_SERVICE_5001_URIS               ?= $(USER_IPFS_SERVICE_URIS)
USER_IPFS_SERVICE_8080_TAGS               ?= $(call urlprefix,,$(USER_IPFS_SERVICE_8080_URIS))
USER_IPFS_SERVICE_8080_URIS               ?= $(USER_IPFS_SERVICE_URIS)
