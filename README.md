# myos - Make Your Own Stack

myos runs docker compose stacks: on a server, in a project directory, for a user.
It is a thin layer over `docker compose` that resolves which compose files to load,
under which project name, with which environment variables.

The framework itself ships no stack. Ready-to-use stacks (consul, fabio, registrator,
postgres, supabase, drone, …) live in a separate catalogue,
[myos-stacks](https://github.com/aya/myos-stacks).

## Disclaimer

This is beta software, use it at your own risks.

## Requirements

`docker` (with the `docker compose` plugin >= 2.24.4, or a `docker-compose` binary),
`git` and `make`.

## Install

### As a command

```sh
sudo git clone https://github.com/aya/myos /usr/local/lib/myos
sudo ln -s /usr/local/lib/myos/myos /usr/local/bin/myos
```

Optionally pin per-machine settings in `/etc/conf.d/myos` (or `/etc/default/myos`),
one `VAR=value` per line, no comments:

```sh
DOMAIN=example.org
ENV=master
```

`myos` runs from the current directory: it passes it as `WORKDIR`, so stacks and
`.env` are looked up there. A `WORKDIR` set in the config file wins over the current
directory, which pins a machine to its deployment directory.

### As a make include

Add to your project `Makefile`:

```make
MYOS ?= /usr/local/lib/myos
-include $(MYOS)/make/include.mk
```

Then `make help` lists the available targets.

### Stack catalogue

myos looks for stacks in `./stack`, `../stack`, `~/.local/share/myos/stack`,
`/usr/local/share/myos/stack` and `/usr/share/myos/stack`:

```sh
sudo git clone https://github.com/aya/myos-stacks /usr/local/share/myos
```

## Usage

```sh
myos up                          # the stack of the current directory
myos up STACK=host               # a group of stacks, see stack/host/host.mk
myos up STACK=host/fabio         # a single stack
myos up STACK=postgres:9.6       # a versioned stack
myos ps
myos logs
myos config                      # rendered compose file
myos down
myos shutdown                    # every stack: app, host and user
```

### How a stack is resolved

A stack is a directory of compose files. For `STACK=<name>` in environment `ENV`,
myos loads, in order, whichever of these exist:

```
<name>.yml   <name>.<ENV>.yml   <ENV>/<name>.yml
<name>.<suffix>.yml   <name>.<suffix>.<ENV>.yml   <name>.<version>.yml
```

`<suffix>` comes from the `COMPOSE_FILE_*` variables that are not `false`
(`app`, `labels`, `networks`, `ssh`, `volumes` by default; add e.g.
`COMPOSE_FILE_WWW=true` to also load `<name>.www.yml`). The framework always
appends its own `share/compose/networks.yml`.

### Project names and networks

| stack | compose project | meaning |
|---|---|---|
| `host/*` | `$(HOSTNAME)` | one instance per machine: ports 80/443, consul, certbot |
| `User/*` | user identity | one instance per user |
| anything else | `<user>-<app>-<env>` | many instances per machine |

Networks: `default` = `_<project>` (private to the project), `private` =
`<user>-<env>` and `public` = `<hostname>`, both external and created on demand.

## Variables

| variable | effect |
|---|---|
| `DEBUG=true` | show executed commands |
| `DRYRUN=true` | print commands instead of running them |
| `VERBOSE=true` | show called functions |
| `ENV=<env>` | environment: selects `.env.<env>` and the `<name>.<env>.yml` overlays |
| `STACK=<refs>` | stacks to act on |
| `SERVICE=<name>` | target one compose service (`exec`, `run`, `logs`, `scale`) |

```sh
myos print-COMPOSE_FILE           # show a variable
myos print-COMPOSE_PROJECT_NAME
myos debug                        # show debug variables
myos doc                          # self documentation from the make comments
```

`SETUP_UFW=true` enables the ufw/ufw-docker integration (`myos setup-ufw`).

## Tests

```sh
make test           # shellspec: unit + golden (a mocked docker, no daemon needed)
make test-golden    # golden only
make golden-record  # re-record the golden expectations
make lint           # shellcheck
```

## License

GPL-3.0, see LICENSE.
