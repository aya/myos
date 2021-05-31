##
# DEPLOY

.PHONY: deploy app-deploy
# target deploy: Run post install hooks in the deployed application
## Called by ansible after creation of the docker application on remote host
deploy: app-deploy deploy-ping ## Run post install hooks in the deployed application

.PHONY: deploy@%
# target deploy@%: Deploy application docker images
##  tag and push docker images to docker registry
##  run ansible-pull on hosts to pull docker images from the registry
##  tag and push docker images as latest to docker registry
deploy@%: myos-base build@% ## Deploy application docker images
	$(call make,docker-login docker-tag docker-push)
	$(call make,myos-ansible-pull@$(ENV) ANSIBLE_DOCKER_IMAGE_TAG=$(VERSION) ANSIBLE_TAGS=aws,,APP AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY)
	$(call make,docker-tag-latest docker-push-latest)

.PHONY: deploy-ping
deploy-ping: deploy-ping-hook

.PHONY: deploy-ping-hook
deploy-ping-hook:
	curl -X POST --data-urlencode 'payload={"text": "$(DEPLOY_HOOK_TEXT)"}' $(DEPLOY_HOOK_URL) ||:
