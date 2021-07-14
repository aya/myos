# docker role for Ansible

Install and configure the [docker](https://www.docker.com/) daemon

## Role Variables

### Default Variables

* `docker_check_kernel` - Minimum kernel version allowed on your hosts to run docker

``` yaml
docker_check_kernel: '3.10'
```

* `docker_daemon_config_directory` - Path to docker daemon configuration files

``` yaml
docker_daemon_config_directory: '/etc/docker'
```

* `docker_daemon_config_file` - Docker daemon configuration file

``` yaml
docker_daemon_config_file: "{{docker_daemon_config_directory}}/daemon.json"
```

* `docker_daemon_config_file` - Docker daemon configuration file

``` yaml
docker_daemon_config_storage: 'overlay2'
```

* `docker_daemon_config` - docker daemon yaml config

``` yaml
docker_daemon_config: { "storage-driver": "devicemapper" }
```

* `docker_package` - Name of the docker package

``` yaml
docker_package: docker-ce
```

* `docker_packages` - List of packages to install/remove before installing the docker package

``` yaml
docker_packages:
  - { "name": "docker", "state": "absent" }
```

* `docker_init_config_directory` - Location of the configuration file of the docker daemon init script

``` yaml
docker_init_config_directory: "/etc/sysconfig"
```

* `docker_opts` - Name of the environment variable used to pass options to the docker daemon

``` yaml
docker_opts: "OPTIONS"
```

* `docker_services` - List of services to enable/disable on your hosts

``` yaml
docker_services:
  - { "name": "docker", "state": "started", "enabled": "yes" }
```

### Deprecated variables

* `dockers` - List of docker images to build and run on the docker host with the docker-build and docker-run commands

``` yaml
dockers: []
```

* `docker_cluster` - Optional cluster name to pass to the docker-build and docker-run commands

``` yaml
docker_cluster: ""
```

* `docker_start` - Starts the dockers if set to true

``` yaml
docker_start: true
```

* `docker_restart` - Restarts dockers when their image has been updated, removes current running dockers and start new ones

``` yaml
docker_restart: true
```

* `docker_force_restart` - Restart dockers, even if image has not been updated, removes current running dockers and start new ones

``` yaml
docker_force_restart: false
```

## Example playbook

``` yaml
- hosts: 'docker'
  roles:
  - role: 'aynicos.docker'
    docker_check_kernel: "3.3"
    docker_package: "docker-ee"
    docker_registry: "hub.docker.com"
```

## Tests

To test this role on your `docker` hosts, run the tests/playbook.yml playbook.

``` bash
$ ansible-playbook tests/playbook.yml
```

## DEPRECATED

Following sections remain of a time where docker compose was borning.

### Helper scripts

This role comes with a few helper scripts. Here is a short description.

* `docker-build` - Build a docker image, reading options to pass to the `docker build` command from a Dockeropts file.

* `docker-cleanup` - Remove unused dockers.

* `docker-cleanup-images` - Remove unused docker images.

* `docker-cleanup-volumes` - Remove unused docker volumes.

* `docker-get-image` - Return sha256 of the image used by the docker.

* `docker-get-status` - Return the status of the docker.

* `docker-log-cleanup` - Empty the file logging the docker output on the docker host.

* `docker-log-truncate` - Truncate the file logging the docker output on the docker host.

* `docker-run` - Run a docker, reading options to pass to the `docker run` command from a Dockeropts file.

### Build a docker image

On the docker hosts, you'll be able to build docker images and run dockers, based on Dockerfile and Dockeropts files located in the /etc/docker subdirectories.

To create an `nginx` docker image, create a directory /etc/docker/nginx with a Dockerfile and a Dockeropts files into.

``` bash
# mkdir -p /etc/docker/nginx
# cat << EOF > /etc/docker/nginx/Dockerfile
FROM nginx:alpine
EOF
# cat << EOF > /etc/docker/nginx/Dockeropts
DOCKER_ULIMIT="nofile=65536"
DOCKER_PORT="80:80"
EOF
```

Build your `nginx` docker image, then run it ! The docker-run command will read the Dockeropts file to add the --ulimit and --port options to the docker run command.

``` bash
# docker-build nginx && docker-run nginx
```

### Override your files

If you want to copy a file in your Dockerfile, say the default nginx.conf, you can use the DOCKER_BUILD_PREFIX and DOCKER_BUILD_SUFFIX variables to get different versions of this file giving some context.

``` bash
# cat << EOF > /etc/docker/nginx/Dockerfile
FROM nginx:alpine
ARG DOCKER_BUILD_PREFIX
ARG DOCKER_BUILD_SUFFIX
COPY ./\${DOCKER_BUILD_PREFIX}nginx.conf\${DOCKER_BUILD_SUFFIX} /etc/nginx/nginx.conf
EOF
```

You can now override the nginx configuration file when you build your image.

* Without option, the docker-build command will search for the file beside your Dockerfile.

``` bash
# docker-build nginx && docker-run nginx
```

Both DOCKER_BUILD_PREFIX and DOCKER_BUILD_SUFFIX variables are empty, the Dockerfile will search for a `./nginx.conf` file, ie the /etc/docker/nginx/nginx.conf file.

* With a -c|--cluster option, the docker-build command will search for the file in a subdirectory below your Dockerfile.

``` bash
# docker-build -c custom nginx && docker-run -c custom nginx
```

The DOCKER_BUILD_PREFIX variable is populated with 'custom/' to force the Dockerfile to search for a `./custom/nginx.conf` file, ie /etc/docker/nginx/custom/nginx.conf file.

* Whith an image name suffixed with a dash, the docker-build command will search for a suffixed file as well.

``` bash
# docker-build -c custom nginx-develop && docker-run -c custom nginx-develop
```

The DOCKER_BUILD_PREFIX variable is populated with 'custom/' and the DOCKER_BUILD_SUFFIX variable is populated with '-develop' to force the Dockerfile to search for a `./custom/nginx.conf-develop` file, ie /etc/docker/nginx/custom/nginx.conf-develop file.

### Override your options

The same override principle can be used for the Dockerfile and the Dockeropts file when using the docker-build and docker-run commands.
You can create a /etc/docker/nginx/custom/Dockeropts file that would override your default Dockeropt file, and a /etc/docker/nginx/custom/Dockeropts-develop file overriding both other files too.
The Dockeropts file accepts the following options.

* `SYSCTL` - values to set on the docker host via the sysctl command before running the docker
* `DOCKER_ARGS` - values to pass to the docker build command with --build-arg options
* `DOCKER_ENV` - values to pass to the docker run command with -e options
* `DOCKER_LINK` - values to pass to the docker run command with --link options
* `DOCKER_OPT` - values to pass to the docker run command with prefixed by --
* `DOCKER_PORT` - values to pass to the docker run command with -p options
* `DOCKER_ULIMIT` - values to pass to the docker run command with --ulimit options
* `DOCKER_VOLUME` - values to pass to the docker run command with -v options
* `HOST_VOLUME` - volumes to allow write access to from the docker on selinux enabled host 

Overriding options is done several times, reading options from the more specific to the more generic file. In our example, files are read in this order :
/etc/docker/nginx/custom/Dockeropts-develop
/etc/docker/nginx/custom/Dockeropts
/etc/docker/nginx/Dockeropts

### Common configuration

Following configuration builds and runs the docker image 'nginx-develop' for the 'custom' cluster described in our example.
The Dockerfile and Dockeropts files needed in the /etc/docker/nginx directory should be present on the docker host, likely synchronised by an other ansible role.

``` yaml
docker_cluster: "custom"
docker:
  - nginx-develop
```

## Limitations

This role is known to work on Ubuntu, Debian, CentOS and Alpine Linux.
