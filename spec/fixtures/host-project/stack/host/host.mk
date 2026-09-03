# Stack host: consul + fabio (80/443) + registrator, one instance per host.
host                            ?= host/consul host/fabio host/registrator

.PHONY: host
host:
	$(call make,up STACK="$(host)")

.PHONY: host-down
host-down:
	$(call make,down STACK="$(host)")
