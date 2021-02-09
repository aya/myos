CMDS                            += openstack ssh-run terraform
COMPOSE_IGNORE_ORPHANS          ?= true
CONTEXT                         += GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME
DOCKER_BUILD_VARS               += SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PUBLIC_HOST_KEYS SSH_PRIVATE_IP_RANGE
DOCKER_SERVICE                  ?= cli
ELASTICSEARCH_HOST              ?= elasticsearch
ELASTICSEARCH_PORT              ?= 9200
ELASTICSEARCH_PROTOCOL          ?= http
ENV_VARS                        += COMPOSE_IGNORE_ORPHANS DOCKER_IMAGE_CLI DOCKER_IMAGE_SSH DOCKER_NAME_CLI DOCKER_NAME_SSH ELASTICSEARCH_HOST ELASTICSEARCH_PASSWORD ELASTICSEARCH_PORT ELASTICSEARCH_PROTOCOL ELASTICSEARCH_USERNAME GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME SETUP_SYSCTL_CONFIG SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PUBLIC_HOST_KEYS SSH_PRIVATE_IP_RANGE
GIT_AUTHOR_EMAIL                ?= $(shell git config user.email 2>/dev/null)
GIT_AUTHOR_NAME                 ?= $(shell git config user.name 2>/dev/null)
HOME                            ?= /home/$(USER)
NFS_DISK                        ?= $(NFS_HOST):/$(SHARED)
NFS_OPTIONS                     ?= rw,rsize=8192,wsize=8192,bg,hard,intr,nfsvers=3,noatime,nodiratime,actimeo=3
NFS_PATH                        ?= /srv/$(subst :,,$(NFS_DISK))
SETUP_NFSD                      ?= false
SETUP_NFSD_OSX_CONFIG           ?= nfs.server.bonjour=0 nfs.server.mount.regular_files=1 nfs.server.mount.require_resv_port=0 nfs.server.nfsd_threads=16 nfs.server.async=1
SETUP_SYSCTL                    ?= false
SETUP_SYSCTL_CONFIG             ?= vm.max_map_count=262144 vm.overcommit_memory=1 fs.file-max=8388608 net.core.somaxconn=1024
SHELL                           ?= /bin/sh
SSH_BASTION_HOSTNAME            ?=
SSH_BASTION_USERNAME            ?=
SSH_PUBLIC_HOST_KEYS            ?= $(SSH_REMOTE_HOSTS) $(SSH_BASTION_HOSTNAME)
SSH_PRIVATE_IP_RANGE            ?= 10.10.*
SSH_REMOTE_HOSTS                ?= github.com gitlab.com
STACK                           ?= base logs services

define setup-nfsd-osx
	$(eval dir:=$(or $(1),$(MONOREPO_DIR)))
	$(eval uid:=$(or $(2),$(UID)))
	$(eval gid:=$(or $(3),$(GID)))
	grep "$(dir)" /etc/exports >/dev/null 2>&1 || echo "$(dir) -alldirs -mapall=$(uid):$(gid) localhost" |sudo tee -a /etc/exports >/dev/null
	$(foreach config,$(SETUP_NFSD_OSX_CONFIG),grep "$(config)" /etc/nfs.conf >/dev/null 2>&1 || echo "$(config)" |sudo tee -a /etc/nfs.conf >/dev/null &&) true
	nfsd status >/dev/null || sudo nfsd enable
	showmount -e localhost |grep "$(dir)" >/dev/null 2>&1 || sudo nfsd restart
endef
