CMDS                            += packer
DOCKER_RUN_OPTIONS_PACKER       ?= -p $(PACKER_SSH_PORT):$(PACKER_SSH_PORT) -p $(PACKER_VNC_PORT):$(PACKER_VNC_PORT)
ENV_VARS                        += PACKER_CACHE_DIR PACKER_KEY_INTERVAL PACKER_LOG
KVM_GID                         ?= $(call gid,kvm)
PACKER_ARCH                     ?= $(PACKER_ALPINE_ARCH)
PACKER_BOOT_WAIT                ?= 11s
PACKER_BUILD_ARGS               ?= -on-error=cleanup $(foreach var,$(PACKER_BUILD_VARS),$(if $($(var)),-var $(var)='$($(var))'))
PACKER_BUILD_VARS               += accelerator boot_wait hostname iso_name iso_size output password qemuargs ssh_wait_timeout template username
PACKER_CACHE_DIR                ?= build/cache
PACKER_HOSTNAME                 ?= $(PACKER_TEMPLATE)
PACKER_ISO_DATE                 ?= $(shell stat -c %y $(PACKER_ISO_FILE) 2>/dev/null)
PACKER_ISO_FILES                ?= $(wildcard build/iso/*/*/*.iso)
PACKER_ISO_FILE                  = $(PACKER_OUTPUT)/$(PACKER_ISO_NAME).iso
PACKER_ISO_INFO                  = $(PACKER_OUTPUT)/$(PACKER_ISO_NAME).nfo
PACKER_ISO_NAME                  = $(PACKER_TEMPLATE)-$(PACKER_RELEASE)-$(PACKER_ARCH)
PACKER_ISO_SIZE                 ?= 1024
PACKER_KEY_INTERVAL             ?= 10ms
PACKER_LOG                      ?= 1
PACKER_OUTPUT                   ?= build/iso/$(ENV)/$(PACKER_TEMPLATE)/$(PACKER_RELEASE)-$(PACKER_ARCH)
PACKER_PASSWORD                 ?= $(PACKER_TEMPLATE)
PACKER_QEMU_ACCELERATOR         ?= kvm
PACKER_QEMU_ARCH                ?= $(PACKER_ARCH)
PACKER_QEMU_ARGS                ?= -machine type=pc,accel=$(PACKER_QEMU_ACCELERATOR) -device virtio-rng-pci,rng=rng0,bus=pci.0,addr=0x7 -object rng-random,filename=/dev/urandom,id=rng0
PACKER_RELEASE                  ?= $(PACKER_ALPINE_RELEASE)
PACKER_SSH_ADDRESS              ?= $(if $(ssh_bind_address),$(ssh_bind_address),0.0.0.0)
PACKER_SSH_PORT                 ?= $(if $(ssh_port_max),$(ssh_port_max),2222)
PACKER_SSH_WAIT_TIMEOUT         ?= 42s
PACKER_TEMPLATES                ?= $(wildcard packer/*/*.json)
PACKER_TEMPLATE                 ?= alpine
PACKER_USERNAME                 ?= root
PACKER_VNC_PORT                 ?= $(if $(vnc_port_max),$(vnc_port_max),5900)
PACKER_VNC_ADDRESS              ?= $(if $(vnc_bind_address),$(vnc_bind_address),0.0.0.0)
ifeq ($(DEBUG), true)
PACKER_BUILD_ARGS               += -debug
endif
ifeq ($(FORCE), true)
PACKER_BUILD_ARGS               += -force
endif
ifeq ($(ENV), local)
PACKER_BUILD_ARGS               += -var ssh_port_max=$(PACKER_SSH_PORT) -var vnc_port_max=$(PACKER_VNC_PORT) -var vnc_bind_address=$(PACKER_VNC_ADDRESS)
endif

accelerator                     ?= $(PACKER_QEMU_ACCELERATOR)
boot_wait                       ?= $(PACKER_BOOT_WAIT)
hostname                        ?= $(PACKER_HOSTNAME)
iso_name                        ?= $(PACKER_ISO_NAME)
iso_size                        ?= $(PACKER_ISO_SIZE)
output                          ?= $(PACKER_OUTPUT)
password                        ?= $(PACKER_PASSWORD)
qemuargs                        ?= $(call arrays_of_dquoted_args, $(PACKER_QEMU_ARGS))
ssh_wait_timeout                ?= $(PACKER_SSH_WAIT_TIMEOUT)
template                        ?= $(PACKER_TEMPLATE)
username                        ?= $(PACKER_USERNAME)

ifneq ($(filter $(ENV),$(ENV_DEPLOY)),)
ifeq ($(password), $(template))
password                        := $(or $(shell pwgen -csy -r\' 64 1 2>/dev/null),$(shell date +%s | shasum -a 256 2>/dev/null | base64 | head -c 64))
endif
endif

ifeq ($(HOST_SYSTEM),DARWIN)
ifneq ($(DOCKER), true)
PACKER_QEMU_ACCELERATOR         := hvf
else
PACKER_QEMU_ACCELERATOR         := tcg
PACKER_QEMU_ARGS                += -cpu max,vendor=GenuineIntel,vmware-cpuid-freq=on,+invtsc,+aes,+vmx
endif
else ifeq ($(HOST_SYSTEM),LINUX)
DOCKER_RUN_OPTIONS_PACKER       += $(if $(KVM_GID),--group-add $(KVM_GID)) --device /dev/kvm
else ifeq ($(HOST_SYSTEM),WINDOWS)
PACKER_QEMU_ACCELERATOR         := hax
endif

ifeq ($(DOCKER), true)

# packer ansible provisionner needs:
## empty local ssh agent (ssh-add -D)
## ANSIBLE_SSH_PRIVATE_KEYS set to a key giving access to ANSIBLE_GIT_REPOSITORY without password
## ANSIBLE_AWS_ACCESS_KEY_ID and ANSIBLE_AWS_SECRET_ACCESS_KEY
define packer
	$(call run,$(DOCKER_RUN_OPTIONS_PACKER) $(DOCKER_REPOSITORY)/packer:$(DOCKER_IMAGE_TAG) $(1))
endef
define packer-qemu
	echo Running $(1)
	$(call run,$(DOCKER_RUN_OPTIONS_PACKER) --entrypoint=qemu-system-$(PACKER_QEMU_ARCH) $(DOCKER_REPOSITORY)/packer:$(DOCKER_IMAGE_TAG) $(PACKER_QEMU_ARGS) -m 512m -drive file=$(1)$(comma)format=raw -net nic$(comma)model=virtio -net user$(comma)hostfwd=tcp:$(PACKER_SSH_ADDRESS):$(PACKER_SSH_PORT)-:22 -vnc $(PACKER_VNC_ADDRESS):$(subst 590,,$(PACKER_VNC_PORT)))
endef

else

# function packer: Call run packer with arg 1
define packer
	$(call run,packer $(1))
endef
# function packer-qemu: Call run qemu-system-% for PACKER_QEMU_ARCH
define packer-qemu
	echo Running $(1)
	$(call run,qemu-system-$(PACKER_QEMU_ARCH) $(PACKER_QEMU_ARGS) -m 512m -drive file=$(1)$(comma)format=raw -net nic$(comma)model=virtio -net user$(comma)hostfwd=tcp:$(PACKER_SSH_ADDRESS):$(PACKER_SSH_PORT)-:22 -vnc $(PACKER_VNC_ADDRESS):$(subst 590,,$(PACKER_VNC_PORT)))
endef

endif

# function packer-build: Call packer build with arg 1, Add build infos to file PACKER_ISO_INFO
define packer-build
	$(eval PACKER_TEMPLATE := $(notdir $(basename $(1))))
	echo Building $(PACKER_ISO_FILE)
	$(call packer,build $(PACKER_BUILD_ARGS) $(1))
	echo 'aws_id: $(ANSIBLE_AWS_ACCESS_KEY_ID)'                  > $(PACKER_ISO_INFO)
	echo 'aws_key: $(ANSIBLE_AWS_SECRET_ACCESS_KEY)'            >> $(PACKER_ISO_INFO)
	echo 'aws_region: $(ANSIBLE_AWS_DEFAULT_REGION)'            >> $(PACKER_ISO_INFO)
	echo 'docker_image_tag: $(ANSIBLE_DOCKER_IMAGE_TAG)'        >> $(PACKER_ISO_INFO)
	echo 'docker_registry: $(ANSIBLE_DOCKER_REGISTRY)'          >> $(PACKER_ISO_INFO)
	echo 'env: $(ENV)'                                          >> $(PACKER_ISO_INFO)
	echo 'file: $(PACKER_ISO_FILE)'                             >> $(PACKER_ISO_INFO)
	echo 'git_branch: $(ANSIBLE_GIT_VERSION)'                   >> $(PACKER_ISO_INFO)
	echo 'git_repository: $(ANSIBLE_GIT_REPOSITORY)'            >> $(PACKER_ISO_INFO)
	echo 'git_version: $(VERSION)'                              >> $(PACKER_ISO_INFO)
	echo 'host: $(hostname)'                                    >> $(PACKER_ISO_INFO)
	echo 'link: s3://$(AWS_S3_BUCKET)/$(AWS_S3_KEY)'            >> $(PACKER_ISO_INFO)
	echo 'name: $(iso_name)'                                    >> $(PACKER_ISO_INFO)
	echo 'nfs_disk: $(ANSIBLE_DISKS_NFS_DISK)'                  >> $(PACKER_ISO_INFO)
	echo 'nfs_path: $(ANSIBLE_DISKS_NFS_PATH)'                  >> $(PACKER_ISO_INFO)
	echo 'pass: $(password)'                                    >> $(PACKER_ISO_INFO)
	echo 'size: $(iso_size)'                                    >> $(PACKER_ISO_INFO)
	echo 'ssh_key: $(ANSIBLE_SSH_PRIVATE_KEYS)'                 >> $(PACKER_ISO_INFO)
	echo 'user: $(username)'                                    >> $(PACKER_ISO_INFO)
endef

define arrays_of_dquoted_args
[ $(subst $(dquote) $(dquote),$(dquote)$(comma) $(dquote),$(subst $(dquote) $(dquote)-,$(dquote) ]$(comma) [ $(dquote)-,$(patsubst %,$(dquote)%$(dquote),$1))) ]
endef
