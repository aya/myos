ENV_VARS                                  += HOST_NGINX_LETSENCRYPT_HOST HOST_NGINX_SERVICE_80_TAGS HOST_NGINX_SERVICE_443_TAGS HOST_NGINX_VIRTUAL_HOST
HOST_NGINX_HOST_URIS                      ?= true
HOST_NGINX_LETSENCRYPT_HOST               ?= $(subst $(space),$(comma),$(filter-out *.%,$(subst $(comma),$(space),$(HOST_NGINX_VIRTUAL_HOST))))
HOST_NGINX_SERVICE_HOST_URIS              ?= */
HOST_NGINX_SERVICE_HOST                   ?= $(subst $(comma),$(space),$(HOST_NGINX_VIRTUAL_HOST))
HOST_NGINX_SERVICE_80_HOST                ?= $(HOST_NGINX_SERVICE_HOST)
HOST_NGINX_SERVICE_80_TAGS                ?= $(call urlprefix,,,$(HOST_NGINX_SERVICE_80_URIS) $(call servicenvs,HOST_NGINX,80,URIS))
HOST_NGINX_SERVICE_80_URIS                ?= $(patsubst %,%:80/,$(HOST_NGINX_SERVICE_80_HOST))
HOST_NGINX_SERVICE_80_ENVS                ?= $(if $(HOST_NGINX_HOST_URIS),host)
HOST_NGINX_SERVICE_443_PATH               ?= /
HOST_NGINX_SERVICE_443_HOST               ?= $(patsubst %,%:443,$(HOST_NGINX_SERVICE_HOST))
HOST_NGINX_SERVICE_443_PROTO              ?= https tlsskipverify=true
HOST_NGINX_SERVICE_443_TAGS               ?= $(call tagprefix,HOST_NGINX,443,host)
HOST_NGINX_VIRTUAL_HOST                   ?= $(subst $(space),$(comma),$(APP_HOST))
