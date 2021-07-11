ENV_VARS += DOCKER_HOST_IFACE DOCKER_HOST_INET

# target node: Fire docker-network-create-% for DOCKER_NETWORK_PUBLIC ssl-certs stack-node-up
.PHONY: node
node: bootstrap-docker docker-network-create-$(DOCKER_NETWORK_PUBLIC) ssl-certs stack-node-up
