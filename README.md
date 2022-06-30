# myos - Make Your Own Stack

Docker paas based on docker compose files.

## Disclaimer

This is work in progress ;)

## Usage

### Examples

* Configure myos for domain.tld

```shell
$ make bootstrap DOMAIN=domain.tld
```

* Start myos stacks

```shell
$ make node up STACK='zen'
```

`make node` starts the stack node with docker host services :
- consul (service discovery)
- fabio (load balancer)
- ipfs (inter planetary file system)
- registrator (docker/consul bridge)
`make User` starts the stack User with docker user services :
- myos (ssh-agent)
- ipfs (when STACK=zen)
`make up` starts the stack STACK
- zen (when STACK=zen)

* Stop myos

```shell
$ make shutdown
```

* Install myos

```shell
$ make install
```

### Variables

* DEBUG

Show executed commands

```shell
$ make up DEBUG=true
```

* DRYRUN

Do nothing, show commands instead of executing it

```shell
$ make up DRYRUN=true
```

* VERBOSE

Show called functions

```shell
$ make up VERBOSE=true
```

* Show variable VARIABLE

```shell
$ make print-VARIABLE
```

### Debug

* Show docker compose yaml config

```shell
$ make config
```

`make config` show docker compose yaml config for stack STACK
`make stack-node-config` show docker compose yaml config for stack node
`make stack-User-config` show docker compose yaml config for stack User
`make stack-elastic-config` show docker compose yaml config for stack elastic

* Show debug variables

```shell
$ make debug
```

* Generate self documentation

```shell
$ make doc
```

* Show env args

```shell
$ make print-env_args
```

## Status

Use it at your own risks.
