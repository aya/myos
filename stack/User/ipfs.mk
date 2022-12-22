ENV_VARS                                  += USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN USER_IPFS_LETSENCRYPT_HOST USER_IPFS_SERVICE_5001_TAGS USER_IPFS_SERVICE_8080_TAGS
USER_IPFS_API_HTTPHEADERS_ACA_ORIGIN      ?= [$(call patsublist,%,"https://%",$(patsubst %/,%,$(USER_IPFS_SERVICE_8080_URIS)))]
USER_IPFS_LETSENCRYPT_HOST                ?= $(subst $(space),$(comma),$(call uriprefix,USER_IPFS,,$(USER_HOST)))
USER_IPFS_SERVICE_NAME                    ?= ipfs
USER_IPFS_SERVICE_5001_PATH               ?= api/
USER_IPFS_SERVICE_5001_TAGS               ?= $(or $(USER_IPFS_SERVICE_5001_TAGS_LOCALHOST),$(USER_IPFS_SERVICE_5001_TAGS_URIS),$(USER_IPFS_SERVICE_5001_TAGS_PROXY_TCP))
USER_IPFS_SERVICE_5001_TAGS_LOCALHOST     ?= $(filter %.localhost/$(USER_PATH)$(USER_IPFS_SERVICE_5001_PATH)$(url_suffix),$(call tagprefix,USER_IPFS,5001))
USER_IPFS_SERVICE_5001_TAGS_PROXY_TCP     ?= $(call patsublist,%,urlprefix-% proxy=tcp,$(USER_IPFS_SERVICE_PROXY_TCP))
USER_IPFS_SERVICE_5001_TAGS_URIS          ?= $(strip $(if $(call servicenvs,USER_IPFS,5001,URIS),$(call urlprefix,$(USER_IPFS_SERVICE_5001_PATH),,$(call servicenvs,USER_IPFS,5001,URIS))))
USER_IPFS_SERVICE_5001_URIS               ?= $(call uriprefix,USER_IPFS,5001,$(USER_URIS))
USER_IPFS_SERVICE_8080_OPTS               ?= $(patsubst %/,%,$(if $(USER_PATH),strip=/$(USER_PATH)))
USER_IPFS_SERVICE_8080_TAGS               ?= $(call tagprefix,USER_IPFS,8080)
USER_IPFS_SERVICE_8080_URIS               ?= $(call uriprefix,USER_IPFS,8080,$(USER_URIS))
