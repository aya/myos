ENV_VARS                                  += USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN USER_IPFS_SERVICE_5001_TAGS USER_IPFS_SERVICE_8080_TAGS
USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN      ?= [$(call patsublist,%,"https://%",$(USER_IPFS_SERVICE_8080_URIS))]
USER_IPFS_SERVICE_NAME                    ?= ipfs
USER_IPFS_SERVICE_5001_PATH               ?= api/
USER_IPFS_SERVICE_5001_TAGS               ?= $(strip $(filter %.localhost/api/$(url_suffix),$(call tagprefix,USER_IPFS,5001)) $(if $(call servicenvs,USER_IPFS,5001,URIS),$(call urlprefix,$(USER_IPFS_SERVICE_5001_PATH),,$(call servicenvs,USER_IPFS,5001,URIS))))
USER_IPFS_SERVICE_5001_URIS               ?= $(call uriprefix,ipfs)
USER_IPFS_SERVICE_8080_TAGS               ?= $(call tagprefix,USER_IPFS,8080)
