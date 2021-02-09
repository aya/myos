# Ansible role to customize servers

An ansible role to customize your servers after a fresh install

## Role Variables

* `hosts_ssh_users` - A list of github usernames. We will fetch ssh keys from their github account and add it to the authorized_keys of the ansible user.

``` yaml
# a list of github usernames to get public keys
hosts_ssh_users: []
```

* `hosts_enable_zram` - Activate zram swap devices. This option allows to create virtual swap devices compressed in RAM. It can increase hosts performances, specially on hosts without physical swap.

``` yaml
# Activate zram swap devices
hosts_enable_zram: false
```

* `hosts_enable_rc` - Run user specific functions on ssh connection. This allow a user to customize his session when connecting to a server, like attaching automaticaly a screen session for example.

``` yaml
# run user specific rc functions on ssh connection
hosts_enable_rc: false
```

* `hosts_rc_functions` - List of user specific functions to run on ssh connection. Here you can add any function to be called when you connect to the host. Default functions are available in the /etc/profile.d/rc_functions.sh file.

``` yaml
# list of rc functions to call at user connection
hosts_rc_functions:
    # customize PS1 variable
    - 01_custom_ps1
    # customize PROMPT variable
    # - 02_custom_prompt
    # launch a ssh agent and load all private keys located in ~/.ssh
    # - 03_ssh_agent
    # create and/or attach a tmux session
    # - 04_attach_tmux
    # create and/or attach a screen session
    - 05_attach_screen
```

* `hosts_rc_cleanup` - List of rc functions you do not want to run anymore. If you had previously activated a rc function in `hosts_rc_functions`, you can add it to `hosts_rc_cleanup` to disable it.

``` yaml
# list of rc functions to cleanup (remove files)
# hosts_rc_cleanup:
    # - 03_ssh_agent
    # - 04_attach_tmux
```

* `hosts_etc_bashrc` - The location of the /etc/bashrc file on the current distro

``` yaml
# location of /etc/bashrc
hosts_etc_bashrc: /etc/bashrc
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
  - { "name": "ca-certificates", "state": "present" }
  - { "name": "rsync", "state": "present" }
  - { "name": "screen", "state": "present" }
  - { "name": "tzdata", "state": "present" }
```

## Example

To launch this role on your `hosts` servers, run the default playbook.

``` bash
$ ansible-playbook playbook.yml
```

It will install the following packages : bash, ca-certificates, rsync, screen, tzdata and vim (plus libselinux-python on redhat).

## Common configurations

This example configuration will add the [ssh keys from aya's github user](https://github.com/aya.keys) to your remote ~/.ssh/authorized_keys.
It will create a ~/.rc.d and touch 01_custom_ps1 and 02_attach_screen files into this directory, resulting in a customized PS1 and automaticaly attaching a screen on (re)connection on the remote server.

``` yaml
hosts_ssh_users:
  - aya
hosts_enable_rc: true
hosts_rc_functions:
  - 01_custom_ps1
  - 02_attach_screen
```

## Tests

To test this role on your `hosts` servers, run the tests/playbook.yml playbook.

``` bash
$ ansible-playbook tests/playbook.yml
```
