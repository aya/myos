PACKER_ALPINE_ARCH              ?= x86_64
PACKER_ALPINE_RELEASE           ?= 3.12.0
PACKER_BUILD_VARS               += alpine_arch alpine_release alpine_version
alpine_arch                     ?= $(PACKER_ALPINE_ARCH)
alpine_release                  ?= $(PACKER_ALPINE_RELEASE)
alpine_version                  ?= $(subst $(eval) ,.,$(wordlist 1, 2, $(subst ., ,$(alpine_release))))
