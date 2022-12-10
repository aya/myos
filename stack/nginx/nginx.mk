ENV_VARS                                  += NGINX_DEFAULT_HOST NGINX_SERVICE_80_TAGS NGINX_SERVICE_443_TAGS NGINX_VIRTUAL_HOST
NGINX_SERVICE_HOST                        ?= $(subst $(comma),$(space),$(NGINX_VIRTUAL_HOST))
NGINX_SERVICE_PATH                        ?= /
NGINX_SERVICE_80_HOST                     ?= $(patsubst %,%:80,$(NGINX_SERVICE_HOST))
NGINX_SERVICE_80_TAGS                     ?= $(call tagprefix,nginx,80,host)
NGINX_SERVICE_443_HOST                    ?= $(patsubst %,%:443,$(NGINX_SERVICE_HOST))
NGINX_SERVICE_443_PROTO                   ?= https tlsskipverify=true
NGINX_SERVICE_443_TAGS                    ?= $(call tagprefix,nginx,443,host)
NGINX_DEFAULT_HOST                        ?= $(firstword $(APP_HOST))
NGINX_VIRTUAL_HOST                        ?= $(subst $(space),$(comma),$(APP_HOST))
