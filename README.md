# yaip - Yet Another Internet Project

Terraform a bunch of ressources to host your projects on Internet.

## Disclaimer

This is work in progress ;)

## Requirements

You need `docker`, `git` and `make`.

## Usage

### Examples

* Install yaip for domain localhost

```shell
$ make install DOMAIN=localhost
```

* Build an iso

```shell
$ make packer-build
```

### Variables

* DRYRUN

Do nothing, show commands instead of executing it.

```shell
$ make install DRYRUN=true
```

* VERBOSE

Show called functions.

```shell
$ make install VERBOSE=true
```

### Debug

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
