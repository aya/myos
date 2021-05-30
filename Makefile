include make/include.mk

##
# APP

app-build: myos-base install-build-parameters
	$(call make,docker-compose-build up)
	$(call make,docker-compose-exec ARGS='rm -Rf /root/.npm /log-buffer/*' SERVICE=logagent)
	$(call make,docker-commit)

app-deploy: deploy-ping

app-install: base node up

app-tests:
	echo ENV: $(env)
	echo DOCKER_ENV: $(DOCKER_ENV)
