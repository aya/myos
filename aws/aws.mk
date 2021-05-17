.PHONY: aws
aws: docker-build-aws
	$(call aws,$(ARGS))

.PHONY: aws-codedeploy
aws-codedeploy:
	$(call aws,deploy create-deployment \
				--application-name $(CODEDEPLOY_APP_NAME) \
		        --deployment-config-name $(CODEDEPLOY_DEPLOYMENT_CONFIG) \
		        --deployment-group-name $(CODEDEPLOY_DEPLOYMENT_GROUP) \
		        --description "$(CODEDEPLOY_DESCRIPTION)" \
		        --github-location repository=$(CODEDEPLOY_GITHUB_REPO)$(comma)commitId=$(CODEDEPLOY_GITHUB_COMMIT_ID))

.PHONY: aws-role-create-import-image
aws-role-create-import-image: aws-iam-create-role-$(AWS_VM_IMPORT_ROLE_NAME)  aws-iam-put-role-policy-$(AWS_VM_IMPORT_ROLE_NAME)

.PHONY: aws-ecr-login
aws-ecr-login:
	$(eval DRYRUN_IGNORE := true)
	$(eval docker_login := $(shell $(call aws,ecr get-login --no-include-email --region $(AWS_DEFAULT_REGION))))
	$(eval DRYRUN_IGNORE := FALSE)
	$(ECHO) $(docker_login)

.PHONY: aws-iam-create-role-%
aws-iam-create-role-%: base docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval json := $(shell $(call exec,envsubst < aws/policies/$*-trust.json)))
	$(eval DRYRUN_IGNORE := false)
	$(call aws,iam create-role --role-name $* --assume-role-policy-document '$(json)')

.PHONY: aws-iam-put-role-policy-%
aws-iam-put-role-policy-%: base docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval json := $(shell $(call exec,envsubst < aws/policies/$*.json)))
	$(eval DRYRUN_IGNORE := false)
	$(call aws,iam put-role-policy --role-name $* --policy-name $* --policy-document '$(json)')

.PHONY: aws-s3-check-upload
aws-s3-check-upload: docker-build-aws aws-s3api-head-object-query-etag
	$(eval upload := true)
	$(eval DRYRUN_IGNORE := true)
	$(if $(AWS_S3_KEY_ETAG),$(if $(filter $(AWS_S3_KEY_ETAG),"$(shell cat $(PACKER_ISO_INFO) |awk '$$1 == "etag:" {print $$2}' 2>/dev/null)"),$(eval upload := false)))
	$(eval DRYRUN_IGNORE := false)

.PHONY: aws-s3-cp
aws-s3-cp: docker-build-aws $(PACKER_ISO_FILE) aws-s3-check-upload
	$(if $(filter $(upload),true),$(call aws,s3 cp $(PACKER_ISO_FILE) s3://$(AWS_S3_BUCKET)/$(AWS_S3_KEY)) $(call make,aws-s3-etag-save))

.PHONY: aws-s3-etag-save
aws-s3-etag-save: docker-build-aws aws-s3api-head-object-query-etag
	echo "etag: $(AWS_S3_KEY_ETAG)" >> $(PACKER_ISO_INFO)

.PHONY: aws-s3api-head-object-query-etag
aws-s3api-head-object-query-etag: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_S3_KEY_ETAG := $(shell $(call aws,s3api head-object --bucket $(AWS_S3_BUCKET) --key $(AWS_S3_KEY) --output text --query ETag) |grep -v 'operation: Not Found' 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo ETag: $(AWS_S3_KEY_ETAG)

.PHONY: aws-s3api-head-object-query-lastmodified
aws-s3api-head-object-query-lastmodified: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_S3_KEY_DATE := $(shell $(call aws,s3api head-object --bucket $(AWS_S3_BUCKET) --key $(AWS_S3_KEY) --output text --query LastModified) |grep -v 'operation: Not Found' 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo LastModified: $(AWS_S3_KEY_DATE)

.PHONY: aws-ec2-import-snapshot
aws-ec2-import-snapshot: base docker-build-aws aws-s3api-head-object-query-etag aws-s3api-head-object-query-lastmodified
	$(eval DRYRUN_IGNORE := true)
	$(eval json := $(shell $(call exec,envsubst < aws/import-snapshot.json)))
	$(eval DRYRUN_IGNORE := false)
	$(eval AWS_TASK_ID := $(shell $(call aws,ec2 import-snapshot --description '$(AWS_SNAP_DESCRIPTION)' --output text --query ImportTaskId --disk-container '$(json)')))
	echo ImportTaskId: $(AWS_TASK_ID)

.PHONY: aws-ec2-describe-import-snapshot-task-%
aws-ec2-describe-import-snapshot-task-%: docker-build-aws
	$(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $*)

.PHONY: aws-ec2-describe-import-snapshot-tasks
aws-ec2-describe-import-snapshot-tasks: docker-build-aws
	$(call aws,ec2 describe-import-snapshot-tasks)

.PHONY: aws-ec2-describe-instance-PrivateIpAddress
aws-ec2-describe-instance-PrivateIpAddress: docker-build-aws
	$(call aws,ec2 describe-instances --no-paginate --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value$(comma)PrivateIpAddress]' --output text) |sed '$$!N;s/\r\n/ /' |awk 'BEGIN {printf "%-24s%s\r\n"$(comma)"PrivateIpAddress"$(comma)"Name"}; $$1 != "None" {printf "%-24s%s\n"$(comma)$$1$(comma)$$2}'

.PHONY: aws-ec2-describe-instance-PrivateIpAddress-%
aws-ec2-describe-instance-PrivateIpAddress-%: docker-build-aws
	$(call aws,ec2 describe-instances --no-paginate --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value$(comma)PrivateIpAddress]' --output text) |sed '$$!N;s/\r\n/ /' |awk 'BEGIN {printf "%-24s%s\r\n"$(comma)"PrivateIpAddress"$(comma)"Name"}; $$1 != "None" && $$2 ~ /$*/ {printf "%-24s%s\n"$(comma)$$1$(comma)$$2}'

.PHONY: aws-ec2-get-PrivateIpAddress
aws-ec2-get-PrivateIpAddress: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_INSTANCE_IP := $(shell $(call aws,ec2 describe-instances --no-paginate --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo PrivateIpAddress: $(AWS_INSTANCE_IP)

.PHONY: aws-ec2-get-PrivateIpAddress-%
aws-ec2-get-PrivateIpAddress-%:
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_INSTANCE_IP := $(shell $(call aws,ec2 describe-instances --no-paginate --filter 'Name=tag:Name$(comma)Values=$**' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo PrivateIpAddress: $(AWS_INSTANCE_IP)

.PHONY: aws-ec2-get-snap-id-import-snapshot-task
aws-ec2-get-snap-id-import-snapshot-task: aws-ec2-get-snap-id-import-snapshot-task-$(AWS_TASK_ID)

.PHONY: aws-ec2-get-snap-id-import-snapshot-task-%
aws-ec2-get-snap-id-import-snapshot-task-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_ID := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.SnapshotId) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo SnapshotId: $(AWS_SNAP_ID)

.PHONY: aws-ec2-get-snap-message-import-snapshot-task-%
aws-ec2-get-snap-message-import-snapshot-task-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_MESSAGE := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.StatusMessage) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo StatusMessage: $(AWS_SNAP_MESSAGE)

.PHONY: aws-ec2-get-snap-progress-import-snapshot-task-%
aws-ec2-get-snap-progress-import-snapshot-task-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_PROGRESS := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.Progress) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo Progress: $(AWS_SNAP_PROGRESS)

.PHONY: aws-ec2-get-snap-size-import-snapshot-task-%
aws-ec2-get-snap-size-import-snapshot-task-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_SIZE := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.DiskImageSize) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo DiskImageSize: $(AWS_SNAP_SIZE)

.PHONY: aws-ec2-get-snap-status-import-snapshot-task-%
aws-ec2-get-snap-status-import-snapshot-task-%: docker-build-aws
	$(eval DRYRUN_IGNORE := true)
	$(eval AWS_SNAP_STATUS := $(shell $(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.Status) 2>/dev/null))
	$(eval DRYRUN_IGNORE := false)
	echo Status: $(AWS_SNAP_STATUS)

.PHONY: aws-ec2-wait-snap-completed-import-snapshot-task
aws-ec2-wait-snap-completed-import-snapshot-task: aws-ec2-wait-snap-completed-import-snapshot-task-$(AWS_TASK_ID)

.PHONY: aws-ec2-wait-snap-completed-import-snapshot-task-%
aws-ec2-wait-snap-completed-import-snapshot-task-%: docker-build-aws
	while [ `$(call aws,ec2 describe-import-snapshot-tasks --import-task-ids $* --output text --query ImportSnapshotTasks[0].SnapshotTaskDetail.Status)` != "completed$$(printf '\r')" ]; \
	do \
		count=$$(( $${count:-0}+1 )); \
		[ "$${count}" -eq 99 ] && exit 1; \
		sleep 10; \
	done

.PHONY: aws-ec2-wait-snapshot-%
aws-ec2-wait-snapshot-%: docker-build-aws
	$(call aws,ec2 wait snapshot-completed --snapshot-ids $* --output text)

.PHONY: aws-ec2-register-image
aws-ec2-register-image: base docker-build-aws aws-ec2-get-snap-id-import-snapshot-task
	$(eval DRYRUN_IGNORE := true)
	$(eval json := $(shell $(call exec,envsubst < aws/register-image-device-mappings.json)))
	$(eval DRYRUN_IGNORE := false)
	$(eval AWS_AMI_ID := $(shell $(call aws,ec2 register-image --name '$(AWS_AMI_NAME)' --description '$(AWS_AMI_DESCRIPTION)' --architecture x86_64 --root-device-name /dev/sda1 --virtualization-type hvm --block-device-mappings '$(json)') 2>/dev/null))
	echo ImageId: $(AWS_AMI_ID)

.PHONY: aws-ami
aws-ami: aws-s3-cp aws-ec2-import-snapshot
	$(call make,aws-ec2-wait-snap-completed-import-snapshot-task,,AWS_TASK_ID)
	$(call make,aws-ec2-register-image,,AWS_TASK_ID)
