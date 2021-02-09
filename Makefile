APP_TYPE := infra
include make/include.mk

##
# APP

app-build: build-rm infra-base
	$(call install-parameters,,curator,build)
	$(call make,docker-compose-build)
	$(call make,up)
	$(call make,docker-compose-exec ARGS='rm -Rf /root/.npm /log-buffer/*' SERVICE=logagent)
	$(call make,docker-commit)

app-deploy: deploy-ping

app-install: base node up
