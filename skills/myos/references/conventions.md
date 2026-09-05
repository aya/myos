# Conventions

## Files of a stack

```
stack/<scope>/<name>.yml            the compose file; <name>.<ENV>.yml, <ENV>/<name>.yml,
                                    <name>.<suffix>.yml, <name>.<suffix>.<ENV>.yml overlays
                                    (suffixes: app labels networks ssh volumes, plus any
                                    COMPOSE_FILE_<X>=true, plus the version of the reference)
stack/<scope>/.env.dist             what the user must provide, rendered once into $WORKDIR/.env
stack/<scope>/<name>.settings       computed defaults of the stack (recomputed every run)
stack/<scope>/_stack.settings       computed defaults shared by every stack of the directory
stack/<scope>/<name>.env, _stack.env  plain defaults, and the groups: host=host/consul host/fabio
stack/<scope>/<name>.sh, _stack.sh  shell functions when the language is not enough (set_NAME() { R=...; })
stack/<scope>/actions/<phase>       hooks: pre-backup, post-restore, doctor, cert-dns...
stack/<scope>/justfile              the same hooks as just recipes
stack/<scope>/docker/<image>/Dockerfile   images `myos build` builds
```

A stack given as a path (`.`, `/opt/app`) reads `docker-compose.yml`,
`docker-compose.<ENV>.yml` and `docker/docker-compose.yml` there.

## Values and their layers

The value of a name is the first found in: the command line (`KEY=VALUE`),
the environment, `$WORKDIR/.env.<ENV>`, `$WORKDIR/.env`, a `:=` setting of
the stack (forced), the plain `.env` files of the stack, the `?=` settings of
the stack, the engine (`share/settings/engine.settings`, then built-ins such
as `COMPOSE_PROJECT_NAME`). `myos env --origin` shows where each comes from.
What reaches compose: the names its files reference (`${VAR}`), the names the
settings `export`, and the engine's (`COMPOSE_*`, `DOCKER_NETWORK_*`, `HOSTNAME`,
`USER`, `ENV`, `DOMAIN`, `MYOS_BIND_*`, `APP`).

## The settings language (lib/settings.awk)

```
NAME ?= expr          a default: used when nothing above sets NAME
NAME := expr          owned by the stack: computed even if a plain default exists (the user still wins)
NAME += words         appended
export A B            reach compose and the hooks
${X}  ${X:-fallback}  a value (any layer, lazily; forward references allowed)
${space} ${comma} ${dollar}   the characters an argument can not hold
@fn(a,b,...)          a function; nesting allowed; a comma splits the arguments
!fn(...)              a function that forks (!shell, !jwt, !random, !git)
$$                    a literal $
```

Functions: `tagprefix SVC PORT [ENVS]`, `urlprefix PATH OPTS URIS`, `uri`,
`url`, `servicenvs`, `envprefix`, `patsubst`, `patsublist`, `subst`, `filter`,
`filter-out`, `firstword`, `lastword`, `words`, `wordlist`, `strip`, `if`,
`or`, `and`, `addprefix`, `addsuffix`, `dir`, `notdir`, `lower`, `upper`,
`name`, `join`. `@if` reads a non-blank condition as true, `false` included.

## Routes and certificates

A service publishes itself to the load balancer through consul tags:
`<SVC>_SERVICE_<port>_TAGS ?= @tagprefix(<SVC>,<port>)` gives
`urlprefix-<name>.<host>/<path>* [allow= auth= deny= prepend= proto= register=
strip=]`, from `<SVC>_SERVICE_<port>_NAME`, `_PATH`, `_OPTS`, `_URIS` and the
option settings. `myos cert` derives the certificates from those tags
(`/host/certs/<name>-cert.pem` and `-key.pem` in the host volume, what fabio
reads).

## Networks and ports

`default` is `_<project>`, `private` is `<user>-<env>`, `public` is the
hostname; the framework overlay `share/compose/networks.yml` declares them.
A published port names its bind address: `${MYOS_BIND_PRIVATE:-127.0.0.1}:8080:80`
(this host only), `${MYOS_BIND_MESH}:...` (the overlay network),
`${MYOS_BIND_PUBLIC}` or nothing (the world: host stacks only).

## Projects and names

`host/*` → the hostname; `User/*` → the user identity (`<user>-<domain>`
with dots as dashes); else `<user>-<env>-<app>` where `app` is the first
segment of the reference (`postgres`, `testing`, `duniter`), lowercased,
without dots, dashes and underscores. `MYOS_PROJECT_FORMAT=user-app-env`
restores the historical order.

## Hooks

Phases: `pre-<verb>`, `<verb>`, `post-<verb>`, `on-fail-<verb>` for `backup`,
`restore`, `upgrade`, `cert`; `doctor` (prints `<id> ok|warn|fail [hint]`
lines); `cert-dns` (the dehydrated hook API for dns-01). A hook runs in its
directory with every exported value plus `MYOS_VERB`, `MYOS_PHASE`,
`MYOS_STACK`, `MYOS_STACK_NAME`, `MYOS_STACK_SCOPE`, `MYOS_STACK_DIR`,
`MYOS_PROJECT`, `MYOS_ENV`, `MYOS_WORKDIR`, `MYOS_COMPOSE` (the compose
command with its files and project), `MYOS_COMPOSE_FILES`, `MYOS_BACKUP_DIR`,
`MYOS_DRYRUN`, `MYOS_OUTPUT`, `MYOS_LIB`. Exit 0 ok, 75 skip, else the verb
fails. A sh hook may `. "$MYOS_LIB/api.sh"` for `myos_var`, `myos_run`,
`myos_event`, `myos_fail`.
