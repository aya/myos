ENV_VARS                                  += REDMINE_DB_NAME REDMINE_DB_USER REDMINE_SERVICE_80_TAGS
REDMINE_SERVICE_URIS                      ?= $(patsubst %,redmine.%,$(APP_URIS))
REDMINE_SERVICE_80_TAGS                   ?= $(call urlprefix,,$(REDMINE_SERVICE_80_URIS))
REDMINE_SERVICE_80_URIS                   ?= $(REDMINE_SERVICE_URIS)
REDMINE_DB_NAME                           ?= $(COMPOSE_SERVICE_NAME)-redmine
REDMINE_DB_USER                           ?= $(REDMINE_DB_NAME)
