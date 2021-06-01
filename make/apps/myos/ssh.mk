##
# SSH

# target ssh: Call ssh-connect with command SHELL
.PHONY: ssh
ssh: aws-ec2-get-PrivateIpAddress-$(SERVER_NAME) ## Connect to first remote host
	$(call ssh-connect,$(AWS_INSTANCE_IP),$(SHELL))

# target ssh-connect: Call ssh-connect with command make connect
.PHONY: ssh-connect
ssh-connect: aws-ec2-get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-connect,$(AWS_INSTANCE_IP),make connect $(if $(SERVICE),SERVICE=$(SERVICE)))

# target ssh-connect: Call ssh-connect with command make exec
.PHONY: ssh-exec
ssh-exec: aws-ec2-get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-exec,$(AWS_INSTANCE_IP),make exec $(if $(SERVICE),SERVICE=$(SERVICE)) $(if $(ARGS),ARGS='\''"$(ARGS)"'\''))

# target ssh-run: Call ssh-connect with command make run
.PHONY: ssh-run
ssh-run: aws-ec2-get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-exec,$(AWS_INSTANCE_IP),make run $(if $(SERVICE),SERVICE=$(SERVICE)) $(if $(ARGS),ARGS='\''"$(ARGS)"'\''))
