ENV_VARS += DOCKER_HOST_IFACE DOCKER_HOST_INET IPFS_PROFILE

IPFS_PROFILE ?= $(if $(filter-out amd64 x86_64,$(PROCESSOR_ARCHITECTURE)),lowpower,server)

# target node: Fire docker-network-create-% for DOCKER_NETWORK_PUBLIC node-ssl-certs stack-node-up
.PHONY: node
node: bootstrap-docker docker-network-create-$(DOCKER_NETWORK_PUBLIC) node-ssl-certs stack-node-up
