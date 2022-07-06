# myos - Make Your Own Stack

Docker paas based on docker compose files.

## Disclaimer

This is work in progress ;)

## Requirements

You need `git` and `make`.

## Usage

### Examples

* Configure myos for domain `domain.tld` and stack `zen`

```shell
$ make bootstrap DOMAIN=domain.tld STACK=zen
```

* Start myos stacks

```shell
$ make node up
```

`make node` starts the stack `node` with docker host services :
- consul (service discovery)
- fabio (load balancer)
- ipfs (inter planetary file system)
- registrator (docker/consul bridge)
`make up` starts the stack `zen` with docker services :
- ipfs (mount ~/.ipfs)
- zen (mount ~/.zen)

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

`make config` show docker compose yaml config for stack `STACK`
`make node-config` show docker compose yaml config for stack `node`
`make user-config` show docker compose yaml config for stack `User`
`make stack-elastic-config` show docker compose yaml config for stack `elastic`

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

Beta software, use it at your own risks.
