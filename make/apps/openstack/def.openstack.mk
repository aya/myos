CMDARGS                         += openstack
ENV_VARS                        += OS_AUTH_URL OS_TENANT_ID OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_REGION_NAME OS_USER_DOMAIN_NAME OS_PROJECT_DOMAIN_NAME
ifneq ($(DEBUG),)
OPENSTACK_ARGS                  += --debug
endif
ifneq ($(VERBOSE),)
OPENSTACK_ARGS                  += -v
endif

# function openstack: Call run openstack with arg 1
define openstack
	$(call INFO,openstack,$(1))
	$(call run,openstack $(1),$(DOCKER_REPOSITORY)/)
endef
