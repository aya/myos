Disk
====

This role allows you to format extra disks and attach them to different mount points.

You can use it to move the data of different services to another disk.

Configuration
-------------

### Inventory

Because the configuration for additional disks must be stored using the YAML
syntax, you have to write it in a `group_vars` directory.

```yaml
# inventory/group_vars/GROUP_NAME
disks_additional_disks:
 - disk: /dev/sdb
   fstype: ext4
   mount_options: defaults
   mount: /data
   user: www-data
   group: www-data
   disable_periodic_fsck: false
 - disk: /dev/nvme0n1
   part: /dev/nvme0n1p1
   fstype: xfs
   mount_options: defaults,noatime
   mount: /data2
 - device_name: /dev/sdf
   fstype: ext4
   mount_options: defaults
   mount: /data
 - disk: nfs-host:/nfs/export
   fstype: nfs
   mount_options: defaults,noatime
   mount: /mnt/nfs
```

* `disk` is the device, you want to mount.
* `part` is the first partition name. If not specified, `1` will be appended to the disk name.
* `fstype` allows you to choose the filesystem to use with the new disk.
* `mount_options` allows you to specify custom mount options.
* `mount` is the directory where the new disk should be mounted.
* `user` sets owner of the mount directory (default: `root`).
* `group` sets group of the mount directory (default: `root`).
* `disable_periodic_fsck` deactivates the periodic ext3/4 filesystem check for the new disk.

You can add:
* `disks_package_use` is the required package manager module to use (yum, apt, etc). The default 'auto' will use existing facts or try to autodetect it.

The following filesystems are currently supported:
- [btrfs](http://en.wikipedia.org/wiki/BTRFS) *
- [ext2](http://en.wikipedia.org/wiki/Ext2)
- [ext3](http://en.wikipedia.org/wiki/Ext3)
- [ext4](http://en.wikipedia.org/wiki/Ext4)
- [nfs](http://en.wikipedia.org/wiki/Network_File_System) *
- [xfs](http://en.wikipedia.org/wiki/XFS) *

*) Note: To use these filesystems you have to define and install additional software packages. Please estimate the right package names for your operating system.

```yaml
# inventory/group_vars/GROUP_NAME
disks_additional_packages:
  - xfsprogs     # package for mkfs.xfs on RedHat / Ubuntu
  - btrfs-progs  # package for mkfs.btrfs on CentOS / Debian
disks_additional_services:
  - rpc.statd    # start rpc.statd service for nfs
```

How it works
------------

It uses `sfdisk` to partition the disk with a single primary partition spanning the entire disk.
The specified filesystem will then be created with `mkfs`.
Finally the new partition will be mounted to the specified mount path.
