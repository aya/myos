AWS_ACCESS_KEY_ID               ?= $(shell $(call conf,$(HOME)/.aws/credentials,$(or $(AWS_PROFILE),default),aws_access_key_id))
AWS_AMI_DESCRIPTION             ?= app: $(APP) branch: $(BRANCH) env: $(ENV) iso: $(AWS_S3_KEY) user: $(USER) version: $(VERSION)
AWS_AMI_NAME                    ?= $(USER)/$(ENV)/$(APP)/ami/$(VERSION)/$(shell date +%Y%m%dT%H%M%S)
AWS_DEFAULT_REGION              ?= eu-west-1
AWS_DEFAULT_OUTPUT              ?= text
AWS_INSTANCE_ID                 ?= $(shell timeout 0.1 curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
AWS_VM_IMPORT_ROLE_NAME         ?= vmimport
AWS_S3_BUCKET                   ?= $(USER)-$(ENV)-config
AWS_S3_KEY                      ?= $(PACKER_ISO_FILE)
AWS_SECRET_ACCESS_KEY           ?= $(shell $(call conf,$(HOME)/.aws/credentials,$(or $(AWS_PROFILE),default),aws_secret_access_key))
AWS_SNAP_DESCRIPTION            ?= iso: $(AWS_S3_KEY) env: $(ENV) app: $(APP) branch: $(BRANCH) version: $(VERSION) user: $(USER) etag: $(AWS_S3_KEY_ETAG) date: $(AWS_S3_KEY_DATE)
CMDS                            += aws
ENV_VARS                        += AWS_ACCESS_KEY_ID AWS_AMI_DESCRIPTION AWS_AMI_NAME AWS_DEFAULT_OUTPUT AWS_DEFAULT_REGION AWS_INSTANCE_ID AWS_PROFILE AWS_S3_BUCKET AWS_S3_KEY AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SNAP_DESCRIPTION AWS_SNAP_ID

ifeq ($(DOCKER), true)
define aws
	$(call run,$(DOCKER_SSH_AUTH) -v $$HOME/.aws:/root/.aws:ro anigeo/awscli:latest $(1))
endef
else
define aws
	$(call run,aws $(1))
endef
endif
