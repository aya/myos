CMDS                            += openstack
ENV_VARS                        += OS_AUTH_URL OS_TENANT_ID OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_REGION_NAME OS_USER_DOMAIN_NAME OS_PROJECT_DOMAIN_NAME
ifneq ($(DEBUG),)
OPENSTACK_ARGS                  += --debug
endif
ifneq ($(VERBOSE),)
OPENSTACK_ARGS                  += -v
endif

ifeq ($(DOCKER), true)
	# function openstack: Call run DOCKER_REPOSITORY/openstack:DOCKER_IMAGE_TAG with arg 1
define openstack
	$(call INFO,openstack,$(1))
	$(call run,$(DOCKER_REPOSITORY)/openstack:$(DOCKER_IMAGE_TAG) $(1))
endef
else
# function openstack: Call run openstack with arg 1
define openstack
	$(call INFO,openstack,$(1))
	$(call run,openstack $(1))
endef
endif
