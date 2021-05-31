CMDS                            += ssh-run
COMPOSE_IGNORE_ORPHANS          := true
CONTEXT                         += GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME
DOCKER_SERVICE                  ?= cli
ENV_VARS                        += COMPOSE_IGNORE_ORPHANS DOCKER_IMAGE_CLI DOCKER_IMAGE_SSH DOCKER_NAME_CLI DOCKER_NAME_SSH
HOME                            ?= /home/$(USER)
NFS_DISK                        ?= $(NFS_HOST):/$(SHARED)
NFS_OPTIONS                     ?= rw,rsize=8192,wsize=8192,bg,hard,intr,nfsvers=3,noatime,nodiratime,actimeo=3
NFS_PATH                        ?= /srv/$(subst :,,$(NFS_DISK))
SHELL                           ?= /bin/sh
STACK                           ?= base
