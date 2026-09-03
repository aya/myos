host ?= host/consul host/fabio

# a target of the project, on top of the myos commands: this is what make is
# kept for, and what the shim leaves alone
.PHONY: host-certs
host-certs:
	@echo "would renew the certificates of $(host)"
