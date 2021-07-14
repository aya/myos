# hosts role for Ansible

Bootstrap hosts, installing standard packages and user settings

## Role Variables

* `hosts_cloudinit_config` - cloud-init yaml config

``` yaml
hosts_cloudinit_config:
    preserve_hostname: false
    datasource_list:
    - Ec2
    datasource:
      Ec2:
        metadata_urls:
        - 'http://169.254.169.254'
```

* `hosts_cloudinit_enable` - Install and configure cloud-init

``` yaml
hosts_cloudinit_enable: false
```

* `hosts_git_repositories` - Clone git repositories

``` yaml
hosts_git_repositories:
- { "repo": "https://github.com/aynicos/myos", "dest": "/dns/com/github/aynicos/myos", "key_file": "~/.ssh/id_rsa", "version": "master" }
```

* `hosts_packages` - List of packages to install/remove on your hosts, should be overrided for a specific distro

``` yaml
hosts_packages: []
```

* `hosts_packages_common` - List of packages to install/remove on your hosts, common to all distros

``` yaml
hosts_packages_common:
- { "name": "bash", "state": "present" }
```

* `hosts_packages_distro` - List of packages to install/remove on your hosts, specific to a distro

``` yaml
hosts_packages_distro:
- { "name": "vim-nox", "state": "present" }
```

* `hosts_services` - List of services to enable/disable on your hosts

``` yaml
hosts_services:
# Enable ansible, running ansible pull at boot
  - { "name": "ansible", "state": "started", "enabled": "yes" }
# Enable zram, creating virtual swap devices compressed in RAM, usefull on hosts without physical swap to increase performances
  - { "name": "zram", "state": "started", "enabled": "yes" }
```

* `hosts_ssh_authorized_keys` - List of urls to add ssh public keys in ~/.ssh/authorized_keys

``` yaml
hosts_ssh_authorized_keys:
- https://github.com/aynicos.keys
```

* `hosts_ssh_bastion_hostname` - Hostname of ssh bastion added in ~/.ssh/myos/config

``` yaml
hosts_ssh_bastion_hostname: 8.4.2.1
```

* `hosts_ssh_bastion_username` - Username of ssh bastion added in ~/.ssh/myos/config

``` yaml
hosts_ssh_bastion_username: root
```

* `hosts_ssh_private_ip_range` - Ip range proxified through ssh bastion to add in ~/.ssh/myos/config

``` yaml
hosts_ssh_private_ip_range: 10.* 192.168.42.*
```

* `hosts_ssh_private_keys` - List of ssh private keys to copy, default to ~/.ssh/id_rsa

``` yaml
hosts_ssh_private_keys:
- ~/.ssh/id_rsa
```

* `hosts_ssh_public_hosts` - List of host names to add ssh public fingerprints in ~/.ssh/known_hosts

``` yaml
hosts_ssh_public_hosts:
- github.com
- gitlab.com
```

* `hosts_ssh_username` - User to ssh on remote hosts

``` yaml
hosts_ssh_username: root
```

* `hosts_update` - Update hosts every day

``` yaml
hosts_update: false
```

* `hosts_user_env` - List of environment variables to add in file ~/.myos

``` yaml
hosts_user_env:
  - ENV
  - DOCKER
```

* `hosts_user_rc_enable` - Call specific functions on user login, allowing it to customize his session

``` yaml
hosts_user_rc_enable: false
```

* `hosts_user_rc_functions` - List of specific functions to call on user login, defined in /etc/profile.d/rc_functions.sh

``` yaml
hosts_user_rc_functions:
# customize PROMPT variable
- { "path": "10_prompt_set", "state": "touch" }
# customize PS1 variable
- { "path": "10_ps1_set", "state": "touch" }
# create and/or attach a tmux session
- { "path": "20_tmux_attach", "state": "touch" }
# display host infos
- { "path": "30_pfetch", "state": "touch" }
# create and/or attach a screen session
- { "path": "30_screen_attach", "state": "touch" }
# launch ssh agent and load private keys in ~/.ssh
- { "path": "40_ssh_add", "state": "touch" }
# remove tmux_attach
- { "path": "20_tmux_attach", "state": "absent" }
```

## Example playbook

``` yaml
- hosts: 'hosts'
  roles:
  - role: 'aynicos.hosts'
    hosts_services:
    - { "name": "local", "state": "started", "enabled": "yes" }
    - { "name": "zram", "state": "started", "enabled": "yes" }
    hosts_user_rc_enable: true
```

## Tests

To test this role on your `hosts`, run the tests/playbook.yml playbook.

``` bash
$ ansible-playbook tests/playbook.yml
```
