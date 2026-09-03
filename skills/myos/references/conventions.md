# Conventions

## A stack is a directory of compose files

For stack `<name>` in environment `<env>`, myos loads whichever of these exist,
in this order. A later file overrides the ones before it.

```
<name>.yml                 the stack
<name>.<env>.yml           this environment only
<env>/<name>.yml           same, when the stack keeps a directory per environment
<name>.<suffix>.yml        an optional overlay, see below
<name>.<suffix>.<env>.yml
<name>.<version>.yml       when the reference is <name>:<version>
```

`docker-compose.yml` is read under the same rules, so a stack can keep an
upstream `docker-compose.yml` untouched and add its own `<name>.yml` on top.

Then myos appends its own `share/compose/networks.yml`, and the
`volumes.<suffix>.<env>.yml` of the enabled suffixes.

## Overlay suffixes

Every `COMPOSE_FILE_<X>` variable that is not `false` enables the suffix `<x>`.

| variable | default | loads |
|---|---|---|
| `COMPOSE_FILE_APP` | true | `<name>.app.yml` |
| `COMPOSE_FILE_LABELS` | true | `<name>.labels.yml`, the registrator labels |
| `COMPOSE_FILE_NETWORKS` | true | `<name>.networks.yml` |
| `COMPOSE_FILE_SSH` | true | `<name>.ssh.yml` |
| `COMPOSE_FILE_VOLUMES` | true | `<name>.volumes.yml` |
| `COMPOSE_FILE_WWW`, `_DNS`, `_HOME`, `_LOG`, `_BACKUP` | false | the matching overlay, and the framework bind mount |

A value that is neither `true` nor `false` also enables `<suffix>.<value>`:
`COMPOSE_FILE_WWW=nginx` loads `<name>.www.yml` **and** `<name>.www.nginx.yml`.

## Project names

| scope | project | why |
|---|---|---|
| `host/*` | `$HOSTNAME` | a singleton of the machine: one consul, one fabio on 80/443 |
| `User/*` | the user identity derived from the mail address | one per user |
| `cluster/*` | the stack name | one namespace per swarm |
| anything else | `<user>-<env>-<app>` | one per user, environment and app |

`MYOS_PROJECT_FORMAT=user-app-env` restores the older order. **Any deployment
created before the rename must set it**, in its `.env` or in
`/etc/conf.d/myos`; otherwise the containers and volumes of the old project
are orphaned and the stack comes back up empty.

## Networks

| network | name | scope |
|---|---|---|
| `default` | `_<project>` | the project. The leading underscore keeps it first alphabetically, so it is the first interface attached and service names never resolve across stacks. |
| `private` | `<user>-<env>` | external, shared between the stacks of one user and environment |
| `public` | `<hostname>` | external, where the load balancer reaches the services |

`myos up` creates the external ones when they are missing.

## Routing: registrator, consul, fabio

A service is published by labels, which registrator copies into consul, and on
which fabio routes:

```yaml
labels:
  - SERVICE_8000_NAME=${COMPOSE_SERVICE_NAME}-kong-8000
  - SERVICE_8000_TAGS=${SUPABASE_KONG_SERVICE_8000_TAGS:-urlprefix-supabase.localhost/*}
  - SERVICE_8000_CHECK_TCP=true
  - SERVICE_8001_IGNORE=true
```

Registrator only sees ports that are `expose`d, and consul only routes a
service whose check passes.

Tag variables follow `<STACK>_SERVICE_<port>_<KEY>`, with `PATH`, `OPTS`,
`URIS`, `NAME`, and the fabio options `allow`, `auth`, `deny`, `prepend`,
`proto`, `register`, `strip`:

```sh
HOST_NGINX_SERVICE_443_PROTO='https tlsskipverify=true'
DUNITER_V2S_SERVICE_9944_STRIP=/ws
```

## Configuration

Layers, the last one wins:

```
defaults < /etc/conf.d/myos, /etc/default/myos < ~/.config/myos/config
        < <workdir>/.env < <workdir>/.env.<env> < environment < VAR=value on the command line
```

All of them are dotenv: `KEY=value`, `#` comments, optional quotes. They are
parsed, never sourced, so a value may contain a `#` or a `$(...)` without
breaking anything or being executed. The make engine included `.env` as a
makefile, where both broke.

## Per-stack settings

A stack keeps its own settings next to its compose files:

| file | for |
|---|---|
| `<name>.env` | plain values: versions, defaults |
| `<name>.env.<env>` | the same, for one environment |
| `<name>.sh` | values that have to be computed |
| `<name>.mk` | the legacy make snippet; still read for its groups |

A `.sh` hook declares **lazy defaults**: a function named
`myos_default_<VARIABLE>`, called only when the variable has no value, and
called again at each reference. That is the make `?=` on a recursive variable,
in shell:

```sh
# stack/host/fabio.sh
myos_default_HOST_FABIO_VERSION()              { printf '1.6.3'; }
myos_default_HOST_FABIO_SERVICE_9998_NAME()    { printf 'fabio'; }
myos_default_HOST_FABIO_SERVICE_9998_AUTH()    { printf 'default'; }
myos_default_HOST_FABIO_SERVICE_9998_TAGS()    { myos_tagprefix HOST_FABIO 9998; }
```

Two things follow, and they are the point:

- a value given anywhere (environment, `.env`, command line) wins over the
  default, without the hook having to say so;
- the default is computed against the values current **at the moment it is
  read**, so a `DOMAIN` set in a `.env` loaded later is taken into account.

The prefix is not decoration: a bare function named `host` or `test` would be
indistinguishable from the program of that name, and myos would run it.

Helpers available in a hook: `myos_tagprefix`, `myos_urlprefix`, `myos_uri`,
`myos_url`, `myos_envprefix`, `myos_servicenvs`, `myos_var`, `myos_lower`,
`myos_upper`, and `myos_default NAME 'body'` when the name is built at run time.

## Templates: .env.dist

A stack may ship a `.env.dist` listing the variables it expects, with their
defaults. `myos env-update` writes the missing ones into the `.env`, expanding
`${VAR}` against the current values and running `$(command)`:

```sh
# stack/demo/.env.dist
DEMO_IMAGE=alpine:${DEMO_VERSION}
DEMO_VERSION=3.20
DEMO_SECRET=$(openssl rand -hex 16)
```

A line may refer to a variable defined further down. A variable that already
has a value keeps it: the `.env` records choices, it never overwrites them, and
running the command twice changes nothing.

## Groups

A group is a lowercase name whose value lists stacks. It can live in a `.env`,
in the environment, in `<path>/<group>.env`, or in a legacy `<group>.mk`:

```sh
host=host/consul host/fabio host/registrator
testing=drone/drone drone/gc
```

Groups expand recursively. Only lowercase names are considered, so an
environment variable can never be mistaken for a group.
