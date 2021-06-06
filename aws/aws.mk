# target aws: Fire docker-build-aws, Call aws ARGS
.PHONY: aws
aws: docker-build-aws
	$(call aws,$(ARGS))

# target aws-deploy: Call aws deploy create-deployment with application-name CODEDEPLOY_APP_NAME
.PHONY: aws-deploy
aws-deploy:
	$(call aws,deploy create-deployment \
				--application-name $(CODEDEPLOY_APP_NAME) \
		        --deployment-config-name $(CODEDEPLOY_DEPLOYMENT_CONFIG) \
		        --deployment-group-name $(CODEDEPLOY_DEPLOYMENT_GROUP) \
		        --description "$(CODEDEPLOY_DESCRIPTION)" \
		        --github-location repository=$(CODEDEPLOY_GITHUB_REPO)$(comma)commitId=$(CODEDEPLOY_GITHUB_COMMIT_ID))

# target aws-docker-login: Fire aws-ecr-get-login
.PHONY: aws-docker-login
aws-docker-login: aws-ecr-get-login

# target aws-ecr-get-login: Exec 'Call aws ecr get-login'
.PHONY: aws-ecr-get-login
aws-ecr-get-login:
	$(eval DRYRUN_IGNORE := true)
	$(eval docker_login := $(shell $(call aws,ecr get-login --no-include-email --region $(AWS_DEFAULT_REGION))))
	$(eval DRYRUN_IGNORE := FALSE)
	$(ECHO) $(docker_login)

# target aws-iam-create-role-%: Call aws iam create-role with role-name % and role-policy file aws/policies/%-trust.json
.PHONY: aws-iam-create-role-%
aws-iam-create-role-%: base docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval json := $(shell $(call exec,envsubst < aws/policies/$*-trust.json)))
	$(eval DRYRUN_IGNORE := false)
	$(call aws,iam create-role --role-name $* --assume-role-policy-document '$(json)')

# target aws-iam-put-role-policy-%: Call aws iam put-role-policy with policy-name % and policy-document file aws/policies/%.json
.PHONY: aws-iam-put-role-policy-%
aws-iam-put-role-policy-%: base docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval json := $(shell $(call exec,envsubst < aws/policies/$*.json)))
	$(eval DRYRUN_IGNORE := false)
	$(call aws,iam put-role-policy --role-name $* --policy-name $* --policy-document '$(json)')

# target aws-role-create-import-image: Fire aws-iam-create-role-% aws-iam-put-role-policy-% for AWS_VM_IMPORT_ROLE_NAME
.PHONY: aws-role-create-import-image
aws-role-create-import-image: aws-iam-create-role-$(AWS_VM_IMPORT_ROLE_NAME)  aws-iam-put-role-policy-$(AWS_VM_IMPORT_ROLE_NAME)

# target aws-s3-check-upload: Fire aws-s3api-get-head-object-etag, Eval upload=false if remote s3 file already exists
.PHONY: aws-s3-check-upload
aws-s3-check-upload: docker-build-aws aws-s3api-get-head-object-etag
	$(eval upload := true)
	$(eval DRYRUN_IGNORE := true)
	$(if $(AWS_S3_KEY_ETAG),$(if $(filter $(AWS_S3_KEY_ETAG),"$(shell cat $(PACKER_ISO_INFO) |awk '$$1 == "etag:" {print $$2}' 2>/dev/null)"),$(eval upload := false)))
	$(eval DRYRUN_IGNORE := false)

# target aws-s3-cp: Fire aws-s3-check-upload, Call aws s3 cp PACKER_ISO_FILE s3://AWS_S3_BUCKET/AWS_S3_KEY, Call aws-s3-etag-save target
.PHONY: aws-s3-cp
aws-s3-cp: docker-build-aws $(PACKER_ISO_FILE) aws-s3-check-upload
	$(if $(filter $(upload),true),$(call aws,s3 cp $(PACKER_ISO_FILE) s3://$(AWS_S3_BUCKET)/$(AWS_S3_KEY)) $(call make,aws-s3-etag-save))

# target aws-s3-etag-save: Fire aws-s3api-get-head-object-etag, Add line 'etag: AWS_S3_KEY_TAG' to file PACKER_ISO_INFO
.PHONY: aws-s3-etag-save
aws-s3-etag-save: docker-build-aws aws-s3api-get-head-object-etag
	echo "etag: $(AWS_S3_KEY_ETAG)" >> $(PACKER_ISO_INFO)

# target aws-s3api-get-head-object-etag: Eval AWS_S3_KEY_ETAG, Echo 'ETag: AWS_S3_KEY_ETAG'
.PHONY: aws-s3api-get-head-object-etag
aws-s3api-get-head-object-etag: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_S3_KEY_ETAG := $(shell $(call aws,s3api head-object --bucket $(AWS_S3_BUCKET) --key $(AWS_S3_KEY) --output text --query ETag) |grep -v 'operation: Not Found' 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo ETag: $(AWS_S3_KEY_ETAG)

# target aws-s3api-get-head-object-lastmodified: Eval AWS_S3_KEY_DATE, Echo 'LastModified: AWS_S3_KEY_DATE'
.PHONY: aws-s3api-get-head-object-lastmodified
aws-s3api-get-head-object-lastmodified: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_S3_KEY_DATE := $(shell $(call aws,s3api head-object --bucket $(AWS_S3_BUCKET) --key $(AWS_S3_KEY) --output text --query LastModified) |grep -v 'operation: Not Found' 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo LastModified: $(AWS_S3_KEY_DATE)

# target aws-ec2-import-snapshot: Call aws ec2 import-snapshot with S3Bucket AWS_S3_BUCKET and S3Key AWS_S3_KEY
.PHONY: aws-ec2-import-snapshot
aws-ec2-import-snapshot: base docker-build-aws aws-s3api-get-head-object-etag aws-s3api-get-head-object-lastmodified
	$(eval DRYRUN_IGNORE := true)
	$(eval json := $(shell $(call exec,envsubst < aws/import-snapshot.json)))
	$(eval DRYRUN_IGNORE := false)
	$(eval AWS_TASK_ID := $(shell $(call aws,ec2 import-snapshot --description '$(AWS_SNAP_DESCRIPTION)' --output text --query ImportTaskId --disk-container '$(json)')))
	echo ImportTaskId: $(AWS_TASK_ID)

# target aws-ec2-describe-import-snapshot-tasks-%: Call aws ec2 describe-import-snapshot-tasks with import-task-id %
.PHONY: aws-ec2-describe-import-snapshot-tasks-%
aws-ec2-describe-import-snapshot-tasks-%: docker-build-aws
	$(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $*)

# target aws-ec2-describe-import-snapshot-tasks: Call aws ec2 describe-import-snapshots-tasks
.PHONY: aws-ec2-describe-import-snapshot-tasks
aws-ec2-describe-import-snapshot-tasks: docker-build-aws
	$(call aws,ec2 describe-import-snapshot-tasks)

# target aws-ec2-describe-instances-PrivateIpAddress: Call aws ec2 describe-instances, Print list of PrivateIpAddress
.PHONY: aws-ec2-describe-instances-PrivateIpAddress
aws-ec2-describe-instances-PrivateIpAddress: docker-build-aws
	$(call aws,ec2 describe-instances --no-paginate --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value$(comma)PrivateIpAddress]' --output text) |sed '$$!N;s/\r\n/ /' |awk 'BEGIN {printf "%-24s%s\r\n"$(comma)"PrivateIpAddress"$(comma)"Name"}; $$1 != "None" {printf "%-24s%s\n"$(comma)$$1$(comma)$$2}'

# target aws-ec2-describe-instances-PrivateIpAddress-%: Call aws ec2 describe-instances, Print list of PrivateIpAddress for Name matching %
.PHONY: aws-ec2-describe-instances-PrivateIpAddress-%
aws-ec2-describe-instances-PrivateIpAddress-%: docker-build-aws
	$(call aws,ec2 describe-instances --no-paginate --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value$(comma)PrivateIpAddress]' --output text) |sed '$$!N;s/\r\n/ /' |awk 'BEGIN {printf "%-24s%s\r\n"$(comma)"PrivateIpAddress"$(comma)"Name"}; $$1 != "None" && $$2 ~ /$*/ {printf "%-24s%s\n"$(comma)$$1$(comma)$$2}'

# target aws-ec2-get-instances-PrivateIpAddress: Eval AWS_INSTANCE_IP, Echo 'PrivateIpAddress: AWS_INSTANCE_IP'
.PHONY: aws-ec2-get-instances-PrivateIpAddress
aws-ec2-get-instances-PrivateIpAddress: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_INSTANCE_IP := $(shell $(call aws,ec2 describe-instances --no-paginate --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo PrivateIpAddress: $(AWS_INSTANCE_IP)

# target aws-ec2-get-instances-PrivateIpAddress-%: Eval AWS_INSTANCE_IP with Name matching %, Echo 'PrivateIpAddress: AWS_INSTANCE_IP'
.PHONY: aws-ec2-get-instances-PrivateIpAddress-%
aws-ec2-get-instances-PrivateIpAddress-%:
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_INSTANCE_IP := $(shell $(call aws,ec2 describe-instances --no-paginate --filter 'Name=tag:Name$(comma)Values=$**' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo PrivateIpAddress: $(AWS_INSTANCE_IP)

# target aws-ec2-get-import-snapshot-tasks-id: Fire aws-ec2-get-import-snapshot-tasks-id-% for AWS_TASK_ID
.PHONY: aws-ec2-get-import-snapshot-tasks-id
aws-ec2-get-import-snapshot-tasks-id: aws-ec2-get-import-snapshot-tasks-id-$(AWS_TASK_ID)

# target aws-ec2-get-import-snapshot-tasks-id-%: Eval AWS_SNAP_IP with import-task-ids %, Echo 'SnapshotId: AWS_SNAP_IP'
.PHONY: aws-ec2-get-import-snapshot-tasks-id-%
aws-ec2-get-import-snapshot-tasks-id-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_ID := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.SnapshotId) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo SnapshotId: $(AWS_SNAP_ID)

# target aws-ec2-get-import-snapshot-tasks-message-%: Eval AWS_SNAP_MESSAGE with import-task-ids %, Echo 'StatusMessage: AWS_SNAP_MESSAGE'
.PHONY: aws-ec2-get-import-snapshot-tasks-message-%
aws-ec2-get-import-snapshot-tasks-message-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_MESSAGE := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.StatusMessage) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo StatusMessage: $(AWS_SNAP_MESSAGE)

# target aws-ec2-get-import-snapshot-tasks-progress-%: Eval AWS_SNAP_PROGRESS with import-task-ids %, Echo 'Progress: AWS_SNAP_PROGRESS'
.PHONY: aws-ec2-get-import-snapshot-tasks-progress-%
aws-ec2-get-import-snapshot-tasks-progress-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_PROGRESS := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.Progress) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo Progress: $(AWS_SNAP_PROGRESS)

# target aws-ec2-get-import-snapshot-tasks-size-%: Eval AWS_SNAP_SIZE with import-task-ids %, Echo 'DiskImageSize: AWS_SNAP_SIZE'
.PHONY: aws-ec2-get-import-snapshot-tasks-size-%
aws-ec2-get-import-snapshot-tasks-size-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_SIZE := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.DiskImageSize) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo DiskImageSize: $(AWS_SNAP_SIZE)

# target aws-ec2-get-import-snapshot-tasks-status-%: Eval AWS_SNAP_STATUS with import-task-ids %, Echo 'Status: AWS_SNAP_STATUS'
.PHONY: aws-ec2-get-import-snapshot-tasks-status-%
aws-ec2-get-import-snapshot-tasks-status-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_STATUS := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.Status) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo Status: $(AWS_SNAP_STATUS)

# target aws-ec2-wait-import-snapshot-tasks-status-completed: Fire aws-ec2-wait-import-snapshot-tasks-status-completed-% for AWS_TASK_ID
.PHONY: aws-ec2-wait-import-snapshot-tasks-status-completed
aws-ec2-wait-import-snapshot-tasks-status-completed: aws-ec2-wait-import-snapshot-tasks-status-completed-$(AWS_TASK_ID)

# target aws-ec2-wait-import-snapshot-tasks-status-completed-%: Wait SnapshotTaskDetail.Status=completed for import-task-ids %
.PHONY: aws-ec2-wait-import-snapshot-tasks-status-completed-%
aws-ec2-wait-import-snapshot-tasks-status-completed-%: docker-build-aws
	while [ `$(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.Status)` != "completed$$(printf '\r')" ]; \
	do \
		count=$$(( $${count:-0}+1 )); \
		[ "$${count}" -eq 99 ] && exit 1; \
		sleep 10; \
	done

# target aws-ec2-wait-snapshot-completed-%: Call ec2 wait snapshot-completed with shapshot-ids %
.PHONY: aws-ec2-wait-snapshot-completed-%
aws-ec2-wait-snapshot-completed-%: docker-build-aws
	$(call aws,ec2 wait snapshot-completed --snapshot-ids $* --output text)

# target aws-ec2-register-image: Fire aws-ec2-get-import-snapshot-tasks-id, Eval AWS_AMI_ID with Name AWS_AMI_NAME, Echo 'ImageId: AWS_AMI_ID'
.PHONY: aws-ec2-register-image
aws-ec2-register-image: base docker-build-aws aws-ec2-get-import-snapshot-tasks-id
	$(eval DRYRUN_IGNORE := true)
	$(eval json := $(shell $(call exec,envsubst < aws/register-image-device-mappings.json)))
	$(eval DRYRUN_IGNORE := false)
	$(eval AWS_AMI_ID := $(shell $(call aws,ec2 register-image --name '$(AWS_AMI_NAME)' --description '$(AWS_AMI_DESCRIPTION)' --architecture x86_64 --root-device-name /dev/sda1 --virtualization-type hvm --block-device-mappings '$(json)') 2>/dev/null))
	echo ImageId: $(AWS_AMI_ID)

# target aws-ami: Fire aws-s3-cp aws-ec2-import-snapshot, Call aws-ec2-wait-import-snapshot-tasks-status-completed target, Call aws-ec2-register-image target
.PHONY: aws-ami
aws-ami: aws-s3-cp aws-ec2-import-snapshot
	$(call make,aws-ec2-wait-import-snapshot-tasks-status-completed,,AWS_TASK_ID)
	$(call make,aws-ec2-register-image,,AWS_TASK_ID)
