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

## Where a stack lives

The same stack may exist in several directories of the stack path. They are all
loaded, least specific first, so the project has the last word:

```
/usr/local/share/myos/stack/postgres/postgres.yml     the catalogue
./stack/postgres/postgres.local.yml                   the project refines it
./stack/postgres/postgres.sh                          and may redefine a default
```

Nothing has to be copied to change one setting: a value in the project `.env`
already wins over any default a stack ships.

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

## What a stack publishes, and to whom

On linux docker writes its own firewall rules, so a port published with
`ports: ["8080:80"]` answers the internet whatever the host firewall says. The
portable answer is to publish where you mean to, which behaves the same on
linux and on macOS and needs no privilege:

```yaml
services:
  app:
    ports:
      - "${MYOS_BIND_PRIVATE}::8080"     # this host only, reached through fabio
  gateway:
    ports:
      - "${MYOS_BIND_PUBLIC}:443:443"    # the internet, on purpose
  peer:
    ports:
      - "${MYOS_BIND_MESH}::7946"        # the private network between the hosts
```

| scope | address | for |
|---|---|---|
| `private` | `127.0.0.1` | everything the load balancer reaches for you. The default. |
| `public` | `0.0.0.0` | a load balancer, a public DNS or mail service |
| `mesh` | the mesh interface | services shared between the hosts of a fleet |

`MYOS_BIND_PUBLIC`, `MYOS_BIND_PRIVATE` and `MYOS_BIND_MESH` override the
addresses; `MYOS_MESH_IFACE` names the interface when it is not one of
easytier, tun0, tailscale0, mycelium or wg0.

There is nothing else to declare: the scope **is** the binding the file asks
for. A port written `- 80` or `- "9000:9000"` is *unbound*, which means docker
opens it on every address and nobody chose that.

```sh
myos expose             # what each stack publishes, on which address
myos expose --strict    # exits 1 when a port is published without a binding
```

The command reads the compose files as written **and** the resolved
configuration, and shows both: the binding the stack asked for, and the address
it ends up on. Resolving first would lose the difference, since
`${MYOS_BIND_PRIVATE}` and a hand-written `127.0.0.1` both become `127.0.0.1`,
and an unbound port becomes `0.0.0.0` exactly like a deliberate public one.

The split of responsibility: the **scope** belongs to the stack, in its compose
file; the **address** of a scope belongs to the host, in its configuration.

## Certificates

A site gets a certificate by being routed, not by being written down a second
time. `myos cert` reads the same `urlprefix-` tags fabio routes on, and decides
what to ask for:

```sh
myos cert list      # what would be asked for, and over which challenge
myos cert issue     # ask for it
myos cert renew     # what is close to expiry, for a cron
myos cert show      # what exists, and when it expires
```

| a tag routes | myos asks for | challenge |
|---|---|---|
| `app.example.org` | a certificate for that name | http-01 |
| `*.ipns.example.org` | `ipns.example.org` **and** `*.ipns.example.org` | dns-01 |

That is the whole of "per site or wildcard as needed": a wildcard is asked for
where a tag uses one, and it absorbs the concrete names it covers. A wildcard
covers one label, so `*.example.org` absorbs `a.example.org` but not
`a.b.example.org`, which keeps its own certificate.

`MYOS_CERT_MODE=per-site` never asks for a wildcard, which keeps everything on
http-01 and needs no DNS credentials. `wildcard` asks for one per domain.

The issuer is [dehydrated](https://github.com/dehydrated-io/dehydrated), a
shell script, in the `host/dehydrated` stack. It answers http-01 itself on a
port bound to the loopback, which fabio routes
`/.well-known/acme-challenge/` to. A wildcard needs dns-01, so point
`HOST_DEHYDRATED_DNS_HOOK` at your provider's script; it receives dehydrated's
own hook arguments.

Certificates land where fabio looks for them, `<name>-cert.pem` and
`<name>-key.pem` under `/host/certs`, written to a temporary name and moved, so
fabio never reads half a file.

## Groups

A group is a lowercase name whose value lists stacks. It can live in a `.env`,
in the environment, in `<path>/<group>.env`, or in a legacy `<group>.mk`:

```sh
host=host/consul host/fabio host/registrator
testing=drone/drone drone/gc
```

Groups expand recursively. Only lowercase names are considered, so an
environment variable can never be mistaken for a group.
