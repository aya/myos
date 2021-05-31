BUILD_ENV_VARS                  += SYMFONY_ENV

ifneq (,$(filter $(ENV),$(ENV_DEPLOY)))
SYMFONY_ENV                     ?= prod
else
SYMFONY_ENV                     ?= dev
endif
