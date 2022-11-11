##
# DEPLOY

# target deploy@%: Deploy application docker images
## it tags and pushes docker images to docker registry
## it runs ansible-pull on hosts to pull docker images from the registry
## it tags and pushes docker images as latest to docker registry
.PHONY: deploy@%
deploy@%: myos-user build@% ## Deploy application docker images
	$(call make,docker-login docker-tag docker-push)
	$(call make,myos-ansible-pull@$(ENV) ANSIBLE_DOCKER_IMAGE_TAG=$(VERSION) ANSIBLE_TAGS=deploy AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY),,APP)
	$(call make,docker-tag-latest docker-push-latest)

# target deploy-hook: Fire app-deploy deploy-hook-ping
## it is called by ansible in the application dockers launched on remote hosts
.PHONY: deploy-hook app-deploy
deploy-hook: app-deploy deploy-hook-ping

# target deploy-hook-ping: Fire deploy-hook-ping-curl
.PHONY: deploy-hook-ping
deploy-hook-ping: deploy-hook-ping-curl

# target deploy-hook-ping-curl: Post install hook to curl DEPLOY_HOOK_URL
.PHONY: deploy-hook-ping-curl
deploy-hook-ping-curl:
	$(if $(DEPLOY_HOOK_URL),$(RUN) curl -X POST --data-urlencode \
		'payload={"text": "$(DEPLOY_HOOK_TEXT)"}' \
		$(DEPLOY_HOOK_URL) \
	||: )

# target deploy-localhost@%: Deploy application docker images
## it tags and pushes docker images to docker registry
## it runs ansible-pull on localhost to pull docker images from the registry
## it tags and pushes docker images as latest to docker registry
.PHONY: deploy-localhost
deploy-localhost: myos-user build@$(ENV)
	$(call make,docker-login docker-tag docker-push)
	$(call make,myos-ansible-pull ANSIBLE_DOCKER_IMAGE_TAG=$(VERSION) ANSIBLE_TAGS=deploy,,APP MYOS_TAGS_JSON)
	$(call make,docker-tag-latest docker-push-latest)
deploy-localhost: app-deploy deploy-hook-ping
