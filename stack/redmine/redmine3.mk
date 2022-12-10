ENV_VARS                                  += REDMINE3_DB_NAME REDMINE3_DB_USER REDMINE3_SERVICE_80_TAGS
REDMINE3_SERVICE_NAME                     ?= redmine3
REDMINE3_SERVICE_80_NAME                  ?= $(REDMINE3_SERVICE_NAME)
REDMINE3_SERVICE_80_TAGS                  ?= $(call tagprefix,redmine3,80)
REDMINE3_DB_NAME                          ?= $(COMPOSE_SERVICE_NAME)-$(REDMINE3_SERVICE_NAME)
REDMINE3_DB_USER                          ?= $(REDMINE3_DB_NAME)

