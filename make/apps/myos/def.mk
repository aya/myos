CMDS                            += ssh-run
COMPOSE_IGNORE_ORPHANS          := true
ENV_VARS                        += COMPOSE_IGNORE_ORPHANS DOCKER_IMAGE_CLI DOCKER_IMAGE_SSH DOCKER_NAME_CLI DOCKER_NAME_SSH
HOME                            ?= /home/$(USER)
NFS_DISK                        ?= $(NFS_HOST):/$(notdir $(SHARED))
NFS_OPTIONS                     ?= rw,rsize=8192,wsize=8192,bg,hard,intr,nfsvers=3,noatime,nodiratime,actimeo=3
NFS_PATH                        ?= /srv/$(subst $(space),/,$(strip $(call reverse,$(subst ., ,$(NFS_HOST)))))$(subst ..,,$(SHARED))
SHELL                           ?= /bin/sh
STACK                           ?= base
