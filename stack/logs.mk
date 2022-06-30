logs                            ?= sematext/logagent

# target app-build-logagent: Exec 'rm -Rf /root/.npm /log-buffer/*' in docker SERVICE
.PHONY: app-build-logagent
app-build-logagent:
	$(call make,docker-compose-exec ARGS='rm -Rf /root/.npm /log-buffer/*' SERVICE=logagent)
