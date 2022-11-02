ENV_VARS                        += IPFS_DAEMON_ARGS IPFS_PROFILE IPFS_VERSION
IPFS_PROFILE                    ?= $(if $(filter-out amd64 x86_64,$(MACHINE)),lowpower,server)
IPFS_VERSION                    ?= 0.16.0

.PHONY: bootstrap-stack-ipfs
bootstrap-stack-ipfs: ~/.ipfs setup-sysctl

~/.ipfs:
	mkdir -p ~/.ipfs
