CMDS                            += ssh-run
COMPOSE_IGNORE_ORPHANS          := true
ENV_VARS                        += COMPOSE_IGNORE_ORPHANS MYOS_TAGS_JSON
HOME                            ?= /home/$(USER)
MYOS_TAGS_VARS                  ?= env user
MYOS_TAGS_ARGS                  ?= $(foreach var,$(filter $(MYOS_TAGS_VARS),$(MAKE_FILE_VARS)),$(if $($(var)),$(var)='$($(var))'))
MYOS_TAGS_JSON                  ?= "{$(foreach var,$(filter $(MYOS_TAGS_VARS),$(MAKE_FILE_VARS)),$(if $($(var)), '$(var)': '$($(var))'$(comma))) }"
NFS_DISK                        ?= $(NFS_HOST):/$(notdir $(SHARED))
NFS_OPTIONS                     ?= rw,rsize=8192,wsize=8192,bg,hard,intr,nfsvers=3,noatime,nodiratime,actimeo=3
NFS_PATH                        ?= /dns/$(subst $(space),/,$(strip $(call reverse,$(subst ., ,$(NFS_HOST)))))$(subst ..,,$(SHARED))
SHELL                           ?= /bin/sh
STACK                           ?= base

env ?= $(ENV)
user ?= $(USER)
