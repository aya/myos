# Docker SSH Agent

Lets you store your SSH authentication keys in a dockerized ssh-agent that can provide the SSH authentication socket for other containers. Works in OSX and Linux environments.

## Why?

On OSX you cannot simply forward your authentication socket to a docker container to be able to e.g clone private repositories that you have access to. You don't want to copy your private key to all containers either. The solution is to add your keys only once to a long-lived ssh-agent container that can be used by other containers and stopped when not needed anymore.

## How to use

### 0. Build
Navigate to the project directory and launch the following command to build the image:

```
docker build -t docker-ssh-agent:latest -f Dockerfile .
```

### 1. Run a long-lived container

```
docker run -d --name=ssh-agent docker-ssh-agent:latest
```

### 2. Add your ssh keys

Run a temporary container with volume mounted from host that includes your SSH keys. SSH key id_rsa will be added to ssh-agent (you can replace id_rsa with your key name):

```
docker run --rm --volumes-from=ssh-agent -v ~/.ssh:/root/.ssh -it docker-ssh-agent:latest ssh-add /root/.ssh/id_rsa
```

The ssh-agent container is now ready to use.

### 3. Add ssh-agent socket to other container:

#### With docker-compose

If you're using `docker-compose` this is how you forward the socket to a container:

```
  volumes_from:
    - ssh-agent
  environment:
    - SSH_AUTH_SOCK=/tmp/ssh-agent/socket
```

#### Without docker-compose

Here's an example how to run a Ubuntu container that uses the ssh authentication socket:

```
docker run -it --volumes-from=ssh-agent -e SSH_AUTH_SOCK=/tmp/ssh-agent/socket ubuntu:latest /bin/bash
```

#### Disable host key verification in your containers

You may wish to disable the ssh host key verification inside your containers to avoid using interactive mode at all.
You can do it adding the following configuration in the /etc/ssh/ssh_config file of your containers.

```
Host *
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
```

### Deleting keys from the container

Run a temporary container and delete all known keys from ssh-agent:

```
docker run --rm --volumes-from=ssh-agent -it docker-ssh-agent:latest ssh-add -D
```
