##
# UPDATE

## Update /etc/hosts
.PHONY: update-hosts
update-hosts:
ifneq (,$(filter $(ENV),local))
	cat */.env 2>/dev/null |grep -Eo 'urlprefix-[^/]+' |sed 's/urlprefix-//' |while read host; do grep $$host /etc/hosts >/dev/null 2>&1 || { echo "Adding $$host to /etc/hosts"; echo 127.0.0.1 $$host |$(ECHO) sudo tee -a /etc/hosts >/dev/null; }; done
endif

.PHONY: update-$(PARAMETERS)
update-$(PARAMETERS): $(PARAMETERS)

$(PARAMETERS): SSH_PUBLIC_HOST_KEYS := $(PARAMETERS_REMOTE_HOST) $(SSH_BASTION_HOSTNAME) $(SSH_REMOTE_HOSTS)
$(PARAMETERS): MAKE_VARS += SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PRIVATE_IP_RANGE SSH_PUBLIC_HOST_KEYS
$(PARAMETERS): myos-base
	$(call exec,[ -d $(PARAMETERS) ] && cd $(PARAMETERS) && git pull --quiet || git clone --quiet $(GIT_PARAMETERS_REPOSITORY))

## Update release version number in .env
.PHONY: update-release
update-release:
	$(ECHO) awk -v s=RELEASE_INSTALL=$(RELEASE_VERSION) '/^RELEASE_INSTALL=/{$$0=s;f=1} {a[++n]=$$0} END{if(!f)a[++n]=s;for(i=1;i<=n;i++)print a[i]>ARGV[1]}' .env

## Update remotes
.PHONY: update-remotes
update-remotes: myos-base
	$(call exec,git fetch --all --prune --tags -u)

.PHONY: update-remote-%
update-remote-%: myos-base
	$(call exec,git fetch --prune --tags -u $*)

## Update subrepos
.PHONY: update-subrepos
update-subrepos: myos-base git-stash $(APPS) git-unstash ## Update subrepos
	$(call exec,git push upstream $(BRANCH))

.PHONY: update-subrepo-%
update-subrepo-%:
	$(if $(wildcard $*/Makefile),$(call make,update-subrepo,$*))

.PHONY: update-upstream
update-upstream: myos-base .git/refs/remotes/upstream/master
	$(call exec,git fetch --tags upstream)

.git/refs/remotes/upstream/master: myos-base
	$(call exec,git remote add upstream $(GIT_UPSTREAM_REPOSITORY) 2>/dev/null ||:)
