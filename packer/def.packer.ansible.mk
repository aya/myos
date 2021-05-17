PACKER_BUILD_VARS               += ansible_extra_vars ansible_user ansible_verbose
ansible_extra_vars              ?= $(patsubst target=%,target=default,$(ANSIBLE_EXTRA_VARS))
ansible_user                    ?= $(ANSIBLE_USERNAME)
ansible_verbose                 ?= $(ANSIBLE_VERBOSE)
