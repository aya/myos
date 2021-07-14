# disks role for Ansible

Format and mount additional disks

## Role Variables

### Default Variables

* `disks_to_mount` - List of disks to mount:
  * `disable_periodic_fsck` deactivates the periodic ext3/4 filesystem check for the new disk
  * `disk` is the device, you want to mount
  * `fstype` allows you to choose the filesystem to use with the new disk
  * `group` sets group of the mount directory (default: `root`)
  * `mount` is the directory where the new disk should be mounted
  * `mount_options` allows you to specify custom mount options
  * `part` is the first partition name. If not specified, `1` will be appended to the disk name
  * `user` sets owner of the mount directory (default: `root`)

```yaml
# inventory/group_vars/GROUP_NAME
disks_to_mount:
 - disk: /dev/sdb
   fstype: ext4
   mount_options: defaults
   mount: /data1
   user: www-data
   group: www-data
   disable_periodic_fsck: false
 - disk: /dev/nvme0n1
   part: /dev/nvme0n1p1
   fstype: xfs
   mount_options: defaults,noatime
   mount: /data2
 - disk: nfs-host:/nfs/export
   fstype: nfs
   mount_options: defaults,noatime
   mount: /data3
```

The following filesystems are currently supported:
* [btrfs](http://en.wikipedia.org/wiki/BTRFS) *
* [ext2](http://en.wikipedia.org/wiki/Ext2)
* [ext3](http://en.wikipedia.org/wiki/Ext3)
* [ext4](http://en.wikipedia.org/wiki/Ext4)
* [nfs](http://en.wikipedia.org/wiki/Network_File_System) *
* [xfs](http://en.wikipedia.org/wiki/XFS) *

Note: (*) To use these filesystems you have to define and install additional software packages. Please estimate the right package names for your operating system.

* `disks_packages` - List of packages to install/remove on your hosts

```yaml
disks_packages:
  - { "name": "xfsprogs", "state": "present" }     # package for mkfs.xfs on RedHat / Ubuntu
  - { "name": "btrfs-progs", "state": "present" }  # package for mkfs.btrfs on CentOS / Debian
```

* `disks_services` - List of services to enable/disable on your hosts

```yaml
disks_services:
  - { "name": "rpc.statd", "state": "started", "enabled": "yes" }    # start rpc.statd service for nfs
```

### AWS variables

* `aws_ebs_discover` - Discover AWS NVMe EBS disks

```yaml
aws_ebs_discover: false
```

## Example playbook

``` yaml
- hosts: 'disks'
  roles:
  - role: 'aynicos.disks'
    disks_to_mount:
    - disk: /dev/xvdb
      disable_periodic_fsck: true
      fstype: ext4
      mount_options: defaults
      mount: /var/lib/docker
      service: docker
    disks_services:
    - { "name": "rpc.statd", "state": "started", "enabled": "yes" }
```

## How it works

It uses `sfdisk` to partition the disk with a single primary partition spanning the entire disk.
It creates the specified filesystem with `mkfs`.
It mounts the new filesystem to the specified mount path.
