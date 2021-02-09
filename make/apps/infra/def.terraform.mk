CMDS                            += terraform

ifeq ($(DOCKER), true)

# packer ansible provisionner needs:
## empty local ssh agent (ssh-add -D)
## ANSIBLE_SSH_PRIVATE_KEY set to a key giving access to ANSIBLE_GIT_REPOSITORY without password
## ANSIBLE_AWS_ACCESS_KEY_ID and ANSIBLE_AWS_SECRET_ACCESS_KEY
define terraform
$(call run,hashicorp/terraform:light $(1))
endef

else

define terraform
	$(call run,terraform $(1))
endef

endif


