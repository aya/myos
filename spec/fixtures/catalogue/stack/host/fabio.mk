ENV_VARS                                  += HOST_FABIO_PROXY_ADDR HOST_FABIO_PROXY_CS HOST_FABIO_SERVICE_9998_TAGS HOST_FABIO_VERSION
HOST_FABIO_PROXY_ADDR                     ?= $(call subst,$(space),$(comma),$(HOST_FABIO_SERVICE_PROXY_ADDR))
HOST_FABIO_SERVICE_HTTP_ADDR              ?= :80
HOST_FABIO_SERVICE_HTTPS_ADDR             ?= :443;cs=certs
HOST_FABIO_SERVICE_PROXY_ADDR             ?= $(call servicenvs,HOST_FABIO,PROXY,ADDR)
HOST_FABIO_SERVICE_PROXY_ENVS             ?= http https tcp
HOST_FABIO_SERVICE_TCP_ADDR               ?= $(foreach port,$(HOST_FABIO_SERVICE_TCP_PORT),:$(port);proto=tcp)
HOST_FABIO_SERVICE_TCP_PORT               ?=
HOST_FABIO_SERVICE_9998_NAME              ?= fabio
HOST_FABIO_SERVICE_9998_AUTH              ?= default
HOST_FABIO_SERVICE_9998_TAGS              ?= $(call tagprefix,HOST_FABIO,9998)
HOST_FABIO_UFW_UPDATE                     ?= 80/tcp 443/tcp
HOST_FABIO_VERSION                        ?= 1.6.3
