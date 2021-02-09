ENV_VARS                        += OS_AUTH_URL OS_TENANT_ID OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_REGION_NAME OS_USER_DOMAIN_NAME OS_PROJECT_DOMAIN_NAME
ifeq ($(DEBUG), true)
OPENSTACK_ARGS                  += --debug
endif
ifeq ($(ENV), local)
OPENSTACK_ARGS                  += -v
endif

ifeq ($(DOCKER), true)
define openstack
	$(call run,$(DOCKER_SSH_AUTH) $(DOCKER_REPOSITORY)/openstack:$(DOCKER_IMAGE_TAG) $(1))
endef
else
define openstack
	$(call run,openstack $(1))
endef
endif
