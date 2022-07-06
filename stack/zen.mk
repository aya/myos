ifneq ($(filter zen,$(STACK)),)
ifeq ($(filter ipfs,$(STACK)),)
STACK                           += ipfs
endif
ifeq ($(filter node/ipfs,$(node)),)
node                            += node/ipfs
endif
endif

.PHONY: bootstrap-stack-zen
bootstrap-stack-zen: ~/.zen

~/.zen:
	mkdir -p ~/.zen
