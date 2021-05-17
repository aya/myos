APP_TYPE := infra
include make/include.mk

##
# APP

app-build: build-rm myos-base
	$(call install-parameters,,*,build)
	$(call make,docker-compose-build up)
	$(call make,docker-compose-exec ARGS='rm -Rf /root/.npm /log-buffer/*' SERVICE=logagent)
	$(call make,docker-commit)

app-deploy: deploy-ping

app-install: base node up
