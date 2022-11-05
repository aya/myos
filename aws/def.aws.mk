AWS_ACCESS_KEY_ID               := $(if $(AWS_CREDENTIALS),$(shell $(call conf,$(AWS_CREDENTIALS),$(or $(AWS_PROFILE),default),aws_access_key_id)))
AWS_AMI_DESCRIPTION             ?= $(AWS_SERVICE_VERSION)
AWS_AMI_NAME                    ?= $(AWS_SERVICE_NAME)-$(AWS_S3_FILENAME)
AWS_CREDENTIALS                 ?= $(wildcard $(HOME)/.aws/credentials)
AWS_DEFAULT_REGION              ?= eu-west-1
AWS_DEFAULT_OUTPUT              ?= text
AWS_INSTANCE_ID                 ?= $(shell timeout 0.1 curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
AWS_VM_IMPORT_ROLE_NAME         ?= vmimport
AWS_S3_BUCKET                   ?= $(AWS_SERVICE_NAME)
AWS_S3_FILENAME                 ?= $(PACKER_ISO_NAME)
AWS_S3_KEY                      ?= $(PACKER_ISO_FILE)
AWS_SECRET_ACCESS_KEY           := $(if $(AWS_CREDENTIALS),$(shell $(call conf,$(AWS_CREDENTIALS),$(or $(AWS_PROFILE),default),aws_secret_access_key)))
AWS_SERVICE_NAME                ?= $(COMPOSE_SERVICE_NAME)
AWS_SERVICE_VERSION             ?= $(BUILD_DATE)-$(VERSION)
AWS_SNAP_DESCRIPTION            ?= $(AWS_SERVICE_NAME)-$(AWS_SERVICE_VERSION)-$(AWS_S3_FILENAME)
CMDS                            += aws
DOCKER_RUN_VOLUME               += -v $(HOME)/.aws:/home/$(USER)/.aws
ENV_VARS                        += AWS_ACCESS_KEY_ID AWS_AMI_DESCRIPTION AWS_AMI_NAME AWS_DEFAULT_OUTPUT AWS_DEFAULT_REGION AWS_INSTANCE_ID AWS_PROFILE AWS_S3_BUCKET AWS_S3_KEY AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SNAP_DESCRIPTION AWS_SNAP_ID

# function aws: Call run aws with arg 1
define aws
	$(RUN) $(call run,aws $(1),$(DOCKER_REPOSITORY)/)
endef
