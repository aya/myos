ifneq (,$(filter true,$(DRONE)))
# limit to APPS impacted by the commit
ifneq (,$(filter $(DRONE_BUILD_EVENT),pull_request push))
COMMIT_AFTER                    := $(DRONE_COMMIT_AFTER)
COMMIT_BEFORE                   := $(if $(filter 0000000000000000000000000000000000000000,$(DRONE_COMMIT_BEFORE)),upstream/master,$(DRONE_COMMIT_BEFORE))
endif
ifneq (,$(filter $(DRONE_BUILD_EVENT),tag))
COMMIT_AFTER                    := $(DRONE_TAG)
COMMIT_BEFORE                   := $(shell git describe --abbrev=0 --tags $(DRONE_TAG)^)
endif
APPS_IMPACTED                   := $(shell git diff --name-only $(COMMIT_BEFORE) $(COMMIT_AFTER) 2>/dev/null |awk -F '/' 'NF>1 && !seen[$$1]++ {print $$1}')
# prevent drone to make down in infra
APPS                            := $(if $(filter-out down,$(MAKECMDGOALS)),$(filter $(INFRA),$(APPS_IMPACTED))) $(sort $(filter-out $(DIRS) $(INFRA),$(APPS_IMPACTED)))
CONTEXT                         += DRONE_BRANCH DRONE_BUILD_EVENT DRONE_BUILD_NUMBER DRONE_COMMIT_AFTER DRONE_COMMIT_AUTHOR DRONE_COMMIT_AUTHOR_EMAIL DRONE_COMMIT_BEFORE DRONE_COMMIT_REF GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME
endif
