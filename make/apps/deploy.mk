##########
# DEPLOY #
##########

.PHONY: deploy app-deploy
# target deploy: Run post install hooks in the deployed application
## Called by ansible after creation of the docker application on remote host
deploy: app-deploy ## Run post install hooks in the deployed application

.PHONY: deploy@%
# target deploy@%: Deploy application docker images
##  tag and push docker images to docker registry
##  run ansible-pull on hosts to pull docker images from the registry
##  tag and push docker images as latest to docker registry
deploy@%: infra-base build@% ## Deploy application docker images
	$(call make,docker-login docker-tag docker-push)
	$(call make,infra-ansible-pull@$(ENV) ANSIBLE_DOCKER_IMAGE_TAG=$(VERSION) ANSIBLE_TAGS=aws,,APP AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY)
	$(call make,docker-tag-latest docker-push-latest)

.PHONY: deploy-aws-codedeploy-%
deploy-aws-codedeploy-%:
	$(call exec,git fetch subrepo/$(SUBREPO))
ifneq ($(wildcard ../infra),)
	$(call make,aws-codedeploy,../infra,CODEDEPLOY_APP_NAME CODEDEPLOY_DEPLOYMENT_CONFIG CODEDEPLOY_DEPLOYMENT_GROUP CODEDEPLOY_DESCRIPTION CODEDEPLOY_GITHUB_REPO CODEDEPLOY_GITHUB_COMMIT_ID)
endif

.PHONY: deploy-assets-install
deploy-assets-install:
	su -s /bin/sh www-data -c "php app/console --no-interaction assets:install --env=prod"
	su -s /bin/sh www-data -c "php app/console --no-interaction assetic:dump --env=prod"

.PHONY: deploy-cache-clear
deploy-cache-clear:
	su -s /bin/sh www-data -c "php app/console --no-interaction cache:clear --env=prod"

.PHONY: deploy-cache-warmup
deploy-cache-warmup:
	su -s /bin/sh www-data -c "php app/console --no-interaction cache:warmup --env=prod"

.PHONY: deploy-composer
deploy-composer:
	su -s /bin/sh www-data -c "composer install --prefer-dist --optimize-autoloader --no-progress --no-interaction --no-dev"

.PHONY: deploy-doctrine-migrations-migrate
deploy-doctrine-migrations-migrate:
	su -s /bin/sh www-data -c "php app/console --no-interaction doctrine:migrations:migrate"

.PHONY: deploy-npm
deploy-npm: deploy-npm-install deploy-npm-run-build

.PHONY: deploy-npm-install
deploy-npm-install:
	npm set progress=false
	npm install -s

.PHONY: deploy-npm-run-build
deploy-npm-run-build:
	npm run build:prod

.PHONY: deploy-ping
deploy-ping: deploy-ping-slack

.PHONY: deploy-ping-slack
deploy-ping-slack:
	curl -X POST --data-urlencode 'payload={"text": "$(DEPLOY_PING_TEXT)"}' $(DEPLOY_SLACK_HOOK) ||:

.PHONY: deploy-supervisorctl-restart-all
deploy-supervisorctl-restart-all:
	supervisorctl restart all

.PHONY: deploy-supervisorctl-start-all
deploy-supervisorctl-start-all:
	supervisorctl start all

.PHONY: deploy-supervisorctl-stop-all
deploy-supervisorctl-stop-all:
	supervisorctl stop all

.PHONY: deploy-yarn
deploy-yarn: deploy-yarn-install

.PHONY: deploy-yarn-build
deploy-yarn-build:
	yarn build:prod

.PHONY: deploy-yarn-install
deploy-yarn-install:
	yarn install
