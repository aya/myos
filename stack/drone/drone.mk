drone                                     ?= drone/drone drone/drone-runner-docker drone/gc
DRONE_RUNNER_NAME                         ?= drone-runner.${APP_HOST}
DRONE_SERVER_HOST                         ?= drone.${APP_HOST}
DRONE_SERVICE_80_TAGS                     ?= $(patsubst %,urlprefix-%,$(DRONE_SERVICE_80_URIS))
DRONE_SERVICE_80_URIS                     ?= $(patsubst %,drone.%,$(APP_URIS))
DRONE_USER_CREATE                         ?= $(USER):$(GIT_USER),admin:true
DRONE_USER_FILTER                         ?= $(GIT_USER)
ENV_VARS                                  += DRONE_RUNNER_NAME DRONE_SERVER_HOST DRONE_USER_CREATE DRONE_USER_FILTER DRONE_SERVICE_80_TAGS
