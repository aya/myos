##
# SSH

# target get-PrivateIpAddress-%: Fire aws-ec2-get-instances-PrivateIpAddress-%
.PHONY: get-PrivateIpAddress-%
get-PrivateIpAddress-%: aws-ec2-get-instances-PrivateIpAddress-%;

# target ssh: Call ssh-connect ARGS or SHELL
.PHONY: ssh
ssh: get-PrivateIpAddress-$(SERVER_NAME) ## Connect to first remote host
	$(call ssh-connect,$(AWS_INSTANCE_IP),$(if $(ARGS),$(ARGS),$(SHELL)))

# target ssh-connect: Call ssh-connect make connect SERVICE
.PHONY: ssh-connect
ssh-connect: get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-connect,$(AWS_INSTANCE_IP),make connect $(if $(SERVICE),SERVICE=$(SERVICE)))

# target ssh-exec: Call ssh-exec make exec SERVICE ARGS
.PHONY: ssh-exec
ssh-exec: get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-exec,$(AWS_INSTANCE_IP),make exec $(if $(SERVICE),SERVICE=$(SERVICE)) $(if $(ARGS),ARGS='\''"$(ARGS)"'\''))

# target ssh-run: Call ssh-run make run SERVICE ARGS
.PHONY: ssh-run
ssh-run: get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-exec,$(AWS_INSTANCE_IP),make run $(if $(SERVICE),SERVICE=$(SERVICE)) $(if $(ARGS),ARGS='\''"$(ARGS)"'\''))
