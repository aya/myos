APP_DIR                         ?= $(CURDIR)
APP_DOCKER_DIR                  ?= $(DOCKER_DIR)
APP_DOMAIN                      ?= $(patsubst %,$(APP_DOMAIN_PREFIX)%,$(DOMAIN))
APP_DOMAIN_PREFIX               ?= $(if $(HOST_STACK),,$(addsuffix .,$(if $(APP_HOST_MULTI_ENV),$(filter-out $(ENV_DEPLOY),$(ENV))))$(if $(APP_HOST_MULTI_USER),$(USER).))
APP_HOST                        ?= $(patsubst %,$(APP_HOST_PREFIX)%,$(APP_DOMAIN))$(if $(HOST_STACK),$(if $(HOST_LB),$(space)$(DOMAIN)))
APP_HOST_PREFIX                 ?= $(addsuffix .,$(if $(HOST_STACK),$(HOSTNAME),$(if $(APP_HOST_MULTI_APP),$(APP_NAME))))
APP_HOST_MULTI                  ?= false
APP_HOST_MULTI_APP              ?= $(if $(filter true,$(APP_HOST_MULTI)),true)
APP_HOST_MULTI_ENV              ?= $(if $(filter true,$(APP_HOST_MULTI)),true)
APP_HOST_MULTI_USER             ?= $(if $(filter true,$(APP_HOST_MULTI)),true)
APP_INSTALLED                   ?= $(APPS)
APP_PARENT                      ?= $(MONOREPO)
APP_PARENT_DIR                  ?= $(MONOREPO_DIR)
APP_PATH                        += $(APP_PATH_PREFIX)
APP_REPOSITORY                  ?= $(APP_REPOSITORY_URL)
APP_REPOSITORY_HOST             ?= $(shell printf '$(APP_REPOSITORY_URI)\n' |sed 's|/.*||;s|.*@||')
APP_REPOSITORY_PATH             ?= $(shell printf '$(APP_REPOSITORY_URI)\n' |sed 's|[^/]*/||;')
APP_REPOSITORY_SCHEME           ?= $(shell printf '$(APP_REPOSITORY_URL)\n' |sed 's|://.*||;')
APP_REPOSITORY_URI              ?= $(shell printf '$(APP_REPOSITORY_URL)\n' |sed 's|.*://||;')
APP_REPOSITORY_URL              ?= $(GIT_REPOSITORY)
APP_REQUIRED                    ?= $(APP_REPOSITORY)
APP_SCHEME                      ?= https
APP_UPSTREAM_REPOSITORY         ?= $(or $(shell git config --get remote.upstream.url 2>/dev/null),$(GIT_UPSTREAM_REPOSITORY))
APP_URI                         ?= $(patsubst %,%/$(APP_PATH),$(APP_HOST))
APP_URIS                        ?= $(APP_URI)
APP_URL                         ?= $(patsubst %,$(APP_SCHEME)://%,$(APP_URI))
APP_VERSION                     ?= $(VERSION)
CONTEXT                         += APP APPS BRANCH DOMAIN VERSION RELEASE
CONTEXT_DEBUG                   += APP_DIR APP_URL APP_REPOSITORY APP_UPSTREAM_REPOSITORY ENV_DEPLOY
ENV_DEPLOY                      ?= $(patsubst origin/%,%,$(shell git rev-parse --symbolic --remotes=origin |sed '/origin\/HEAD/d' 2>/dev/null))
ENV_VARS                        += APP_DIR APP_DOMAIN APP_HOST APP_PATH APP_URL CONSUL_HTTP_TOKEN $(if $(filter true,$(MOUNT_NFS)),NFS_CONFIG)
MAKECMDARGS                     += exec exec:% exec@% run run:% run@%
MOUNT_NFS                       ?= false
NFS_CONFIG                      ?= addr=$(NFS_HOST),actimeo=3,intr,noacl,noatime,nocto,nodiratime,nolock,soft,rsize=32768,wsize=32768,tcp,rw,vers=3
NFS_HOST                        ?= host.docker.internal
SERVICES                        ?= $(DOCKER_SERVICES)

envprefix  = $(foreach env,$(3),$(if $($(call UPPERCASE,$(1)_SERVICE_$(2)_$(env))),$(env)=$($(call UPPERCASE,$(1)_SERVICE_$(2)_$(env)))))
patsublist = $(patsubst $(1),$(2),$(firstword $(3)))$(foreach pattern,$(wordlist 2,255,$(3)),$(comma)$(patsubst $(1),$(2),$(pattern)))
servicenvs = $(foreach env,$(call UPPERCASE,$($(1)_SERVICE_$(2)_ENVS)),$(if $(3),$($(1)_SERVICE_$(env)_$(3)),$($(1)_SERVICE_$(2)_$(env))))
tagprefix  = $(call urlprefix,$(or $($(call UPPERCASE,$(1)_SERVICE_$(2)_PATH)),$($(call UPPERCASE,$(1)_SERVICE_PATH))),$(or $($(call UPPERCASE,$(1)_SERVICE_$(2)_OPTS)),$($(call UPPERCASE,$(1)_SERVICE_OPTS)),$(call envprefix,$(1),$(2),allow auth deny preprend proto register strip)),$(or $(foreach env,$(3),$($(call UPPERCASE,$(1)_SERVICE_$(2)_$(env)))),$($(call UPPERCASE,$(1)_SERVICE_$(2)_URIS)),$(call uriprefix,$(1),$(2))))
uriprefix  = $(foreach svc,$(1),$(patsubst %,$(addsuffix .,$(or $($(call UPPERCASE,$(svc)_SERVICE_$(2)_NAME)),$($(call UPPERCASE,$(svc)_SERVICE_NAME)),$(svc)))%,$(or $(3),$(APP_URIS))))
url_suffix = *
urlprefix  = $(strip $(call patsublist,%,urlprefix-%$(1)$(url_suffix) $(2),$(or $(3),$(APP_URIS))))
urlprefixs = $(strip $(call urlprefix,$(firstword $(1)),$(wordlist 2,16,$(1)))$(foreach prefix,$(subst $(space),$(dollar),$(2)) $(subst $(space),$(dollar),$(3)) $(subst $(space),$(dollar),$(4)),$(comma)$(call subst,$(dollar),$(space),$(call urlprefix,$(firstword $(prefix)),$(wordlist 2,16,$(prefix))))))
## urlprefix tests (x APP_URI)
# $(call urlprefix)
# urlprefix-app.domain/*
# $(call urlprefix,admin/)
# urlprefix-app.domain/admin/*
# $(call urlprefix,:443/ proto=https,$(APP_HOST))
# urlprefix-app.domain:443/* proto=https
## urlprefixs tests (x prefix)
# $(call urlprefixs,admin strip=/admin,images/)
# urlprefix-app.domain/admin* strip=/admin,urlprefix-app.domain/images/*
