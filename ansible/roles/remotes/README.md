# remotes role for Ansible

Interact with remote services

## Role Variables

### Default variables

* `remotes_packages` - List of packages to install/remove on your hosts

``` yaml
remotes_packages:
- { "name": "remoteit", "state": "present" }
```

* `remotes_pips` - List of python pip packages to install/remove on your hosts

``` yaml
remotes_pips:
- { "name": "awscli", "state": "present" }
- { "name": "docker", "state": "present" }
```

* `remotes_services` - List of services to enable/disable on your hosts

``` yaml
remotes_services:
- { "name": "connectd", "state": "started", "enabled": "yes" }
```

### AWS variables

* `aws_access_key_id` - aws_access_key_id to add in ~/.aws/credentials

``` yaml
aws_access_key_id: 'YOUR_ACCESS_KEY_ID'
```

* `aws_group` - Set group of aws configuration files to `aws_group`

``` yaml
aws_group: 'root'
```

* `aws_output` - output to add in ~/.aws/config

``` yaml
aws_output: json
```

* `aws_region` - region to add in ~/.aws/config

``` yaml
aws_region: 'eu-west-1'
```

* `aws_secret_access_key` - aws_secret_access_key to add in ~/.aws/credentials

``` yaml
aws_secret_access_key: 'YOUR_SECRET_ACCESS_KEY'
```

* `aws_user` - Set owner of aws configuration files to `aws_user`

``` yaml
aws_user: 'root'
```

## Example playbook

``` yaml
- hosts: 'remotes'
  roles:
  - role: 'aynicos.remotes'
    aws_access_key_id: 'YOUR_ACCESS_KEY_ID'
    aws_secret_access_key: 'YOUR_SECRET_ACCESS_KEY'
```
