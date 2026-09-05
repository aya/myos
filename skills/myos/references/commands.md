# Commands

```
myos [options] <command> [stack...] [VAR=value...] [-- args...]
```

| option | effect |
|---|---|
| `-C DIR` | work in DIR instead of the current directory |
| `-e ENV` | environment: picks `.env.<env>` and the `<stack>.<env>.yml` overlays |
| `-n`, `--dry-run` | print the commands instead of running them |
| `-v`, `--verbose` | say what myos is doing |
| `-d`, `--debug` | print every command |

| command | effect |
|---|---|
| `up` | create and start; creates the external networks first |
| `down` | remove the containers |
| `start` / `stop` / `restart` | on the existing containers |
| `ps` | what is running |
| `logs` | follow the logs |
| `config` | the resolved compose file |
| `exec` | run a command in a running service |
| `run` | run it in a new container, removed afterwards |
| `scale` | `myos scale <stack> SERVICE=<name> NUM=<n>` |
| `build` / `pull` | images |
| `ls [--groups]` | the stacks and groups myos can see |
| `env [VAR...]` | resolved variables |
| `env-update` | fill the `.env` from the `.env.dist` templates |
| `expose [--strict]` | what the stacks publish, and to whom |
| `export [--make]` | every setting of the stacks, as `KEY=value` |
| `doctor` | check the installation |
| `version` | the myos version |

## Several commands at once

Commands chain, the way make targets did. Leading words that name commands are
commands; the first word that is not one starts the list of stacks.

```sh
myos build up logs host/fabio        # like: make build up logs STACK=host/fabio
myos up ps host
```

They run in order and stop at the first failure. A stack whose name is also a
command name has to be given as `STACK=<name>`, otherwise it is read as a
command.

Anything after `--` goes to docker compose:

```sh
myos logs host/fabio -- --tail 20
myos up postgres -- --force-recreate
```

`exec` and `run` take the service from the stack name, since most stacks name
their main service after themselves. `SERVICE=` picks another one:

```sh
myos exec host/consul -- consul members        # service consul, command "consul members"
myos exec host/fabio SERVICE=fabio -- sh
myos run postgres -- psql -l
```

## Exit codes

| code | meaning |
|---|---|
| 0 | fine |
| 1 | the command failed |
| 2 | bad invocation, or an unknown command |
| 3 | stack not found (the message prints the search path) |
| 4 | missing requirement, run `myos doctor` |

The make engine exited 0 on an unknown target, printing only a warning. The CLI
does not: a typo is an error.

## Coming from the make targets

| make | myos |
|---|---|
| `make up STACK=host` | `myos up host` |
| `make print-COMPOSE_FILE` | `myos env COMPOSE_FILE` |
| `make host` | `myos up host` (a bare stack name is not a command) |
| `make build up logs STACK=host/fabio` | `myos build up logs host/fabio` |
| `make stack-host-config` | `myos config host` |
| `make up@master` | `myos -e master up` |
| `make exec SERVICE=php ARGS='ls'` | `myos exec <stack> -- php ls` |
| `make DRYRUN=true up` | `myos -n up` |

`print-VAR`, `stack-<stack>-<command>` and `<command>@<env>` still work.
A project `Makefile` that includes `make/include.mk` keeps working too.
