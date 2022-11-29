ENV_VARS                                  += REDMINE3_DB_NAME REDMINE3_DB_USER REDMINE3_SERVICE_80_TAGS
REDMINE3_SERVICE_80_TAGS                  ?= $(patsubst %,urlprefix-%,$(REDMINE3_SERVICE_80_URIS))
REDMINE3_SERVICE_80_URIS                  ?= $(patsubst %,redmine3.%,$(APP_URIS))
REDMINE3_DB_NAME                          ?= $(COMPOSE_SERVICE_NAME)-redmine3
REDMINE3_DB_USER                          ?= $(REDMINE3_DB_NAME)

