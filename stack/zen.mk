ifneq ($(filter zen,$(STACK)),)
ifeq ($(filter User/ipfs,$(STACK)),)
STACK                           += User/ipfs
endif
ifeq ($(filter User/ipfs,$(User)),)
User                            += User/ipfs
endif
endif
