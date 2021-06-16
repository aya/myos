# Ansible role to customize servers

An ansible role to customize servers after a fresh install

## Role Variables

* `hosts_enable_cloudinit` - Install and configure cloud-init

``` yaml
# enable cloud-init
hosts_enable_cloudinit: false
```

* `hosts_enable_local` - Run ansible pull at boot

``` yaml
# enable rc.local script
hosts_enable_local: false
```

* `hosts_enable_rc` - Run user specific functions on ssh connection. This allow a user to customize his session when connecting to a server, like attaching automaticaly a screen session for example.

``` yaml
# run user specific rc functions on ssh connection
hosts_enable_rc: false
```

* `hosts_enable_zram` - Activate zram swap devices. This option allows to create virtual swap devices compressed in RAM. It can increase hosts performances, specially on hosts without physical swap.

``` yaml
# Activate zram swap devices
hosts_enable_zram: false
```

* `hosts_git_repositories` - Clone git repositories.

``` yaml
# git repositories to clone
hosts_git_repositories:
- { "repo": "https://github.com/aya/myos", "dest": "/src/com/github/aya/myos", "key_file": "~/.ssh/id_rsa", "version": "master" }
```

* `hosts_packages` - A list of packages to install on your servers. This list should be overrided for a specific distro.

``` yaml
# packages specific to a distribution
hosts_packages: []
```

* `hosts_packages_common` - A common list of packages to install on your servers. This list should be common to all distros.

``` yaml
# packages common to all distributions
hosts_packages_common:
- { "name": "bash", "state": "present" }
```

* `hosts_packages_distro` - A list of packages to install on your servers. This list is specific to your distro.

``` yaml
# packages specific to a distribution
hosts_packages_distro:
- { "name": "vim-nox", "state": "present" }
```

* `hosts_rc_functions` - List of user specific functions to run on ssh connection. Here you can add any function to be called when you connect to the host. Default functions are available in the /etc/profile.d/rc_functions.sh file.

``` yaml
# list of rc functions to call at user connection
hosts_rc_functions:
# load shell functions
- 00_source
# customize PROMPT variable
- 10_prompt_set
# customize PS1 variable
- 10_ps1_set
# create and/or attach a tmux session
- 20_tmux_attach
# display host infos
- 30_pfetch
# create and/or attach a screen session
- 30_screen_attach
# launch ssh agent and load private keys in ~/.ssh
- 40_ssh_add
```

* `hosts_rc_cleanup` - List of rc functions you do not want to run anymore. If you had previously activated a rc function in `hosts_rc_functions`, you can add it to `hosts_rc_cleanup` to disable it.

``` yaml
# list of rc functions to cleanup (remove files)
hosts_rc_cleanup:
- 01_custom_ps1
- 02_custom_prompt
- 03_ssh_agent
- 04_attach_tmux
- 05_attach_screen
```

* `hosts_ssh_authorized_keys` - A list of urls. Fetch ssh public keys from urls and add them to file ~/.ssh/authorized_keys of the ansible user.

``` yaml
# a list of urls to get ssh public keys
hosts_ssh_authorized_keys:
- https://github.com/aya.keys
```

* `hosts_ssh_bastion_hostname` - Hostname of ssh bastion. Needed to add myos-bastion to file ~/.ssh/myos/config of the ansible user.

``` yaml
# hostname of myos-bastion to add in ~/.ssh/myos/config
hosts_ssh_bastion_hostname: 8.4.2.1
```

* `hosts_ssh_bastion_username` - Username of ssh bastion. Needed to add myos-bastion to file ~/.ssh/myos/config of the ansible user.

``` yaml
# hostname of myos-bastion to add in ~/.ssh/myos/config
hosts_ssh_bastion_username: root
```

* `hosts_ssh_private_ip_range` - Ip range to pass through ssh bastion.

``` yaml
# ip range proxyfied through myos-bastion to add in ~/.ssh/myos/config
hosts_ssh_private_ip_range: 10.* 192.168.42.*
```

* `hosts_ssh_private_keys` - A list of ssh private keys to copy. Default to ~/.ssh/id_rsa

``` yaml
# a list of urls to get ssh public keys
hosts_ssh_private_keys:
- ~/.ssh/id_rsa
```

* `hosts_ssh_public_hosts` - A list of host names to get ssh fingerprint

``` yaml
# a list of public hosts to add to ~/.ssh/known_hosts
hosts_ssh_public_hosts:
- github.com
- gitlab.com
```

* `hosts_ssh_username` - ssh user used to ssh on remote hosts

``` yaml
# ssh username to ssh on remote hosts
hosts_ssh_username: root
```

## Example

To launch this role on your `hosts` servers, run the default playbook.

``` bash
$ ansible-playbook playbook.yml
```

## Tests

To test this role on your `hosts` servers, run the tests/playbook.yml playbook.

``` bash
$ ansible-playbook tests/playbook.yml
```
