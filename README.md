# myos - Make Your Own Stack

myos runs docker compose stacks: on a server, in a project directory, for a
user, on a fleet. It decides which compose files to load, under which project
name, with which values, and it carries the stacks through their life:
bootstrap, up, upgrade, backup, restore, firewall, certificates, doctor.
Everything else is docker.

The framework ships no stack. Ready-to-use stacks (consul, fabio, registrator,
postgres, supabase, ...) live in a separate catalogue,
[myos-stacks](https://github.com/aya/myos-stacks).

## Requirements

`docker` with the `docker compose` plugin (>= 2.21), `git`, a POSIX `sh`
(dash, busybox ash, bash 3.2 all work). Optional: `just` for `just --list`
and for the hooks a stack writes as a justfile, `jq` for reading docker's JSON.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/aya/myos/tdd/install.sh | sh
myos doctor
```

or by hand:

```sh
sudo git clone https://github.com/aya/myos /usr/local/lib/myos
sudo ln -s /usr/local/lib/myos/myos /usr/local/bin/myos
sudo git clone https://github.com/aya/myos-stacks /usr/local/share/myos   # the catalogue
```

Per-machine values go into `/etc/conf.d/myos` (or `/etc/default/myos`), one
`KEY=value` per line: `DOMAIN=example.org`, `ENV=master`, `WORKDIR=/srv/myos`.

## Use

```sh
myos ls                      # the stacks and groups reachable from here
myos -n up host              # what `up host` would run, without running it
myos up host                 # the host stack: consul, fabio, registrator...
myos up postgres:16          # a stack of the catalogue, with its 16 overlay
myos up                      # the current directory, when it holds compose files
myos build up logs myapp     # verbs chain, and stop at the first failure
myos status app --strict     # exit 4 when a service is not running
myos backup app              # the volumes into backup/<project>/<date>/
myos restore app --from latest --yes
myos upgrade app             # backup, pull, build, up, wait for healthy
myos firewall app --strict   # what the stack publishes, and to whom
myos cert host               # the certificates the routes need
myos doctor app --json       # what is missing, one JSON line per check
```

A reference is `[<scope>/]<name>[:<version>]`, or a path. `host/*` stacks are
singletons named after the host; `User/*` stacks belong to the user; anything
else is an application project, `<user>-<env>-<app>` (`MYOS_PROJECT_FORMAT=
user-app-env` keeps the names of a deployment made before this version).

Stacks are looked up along a path, by precedence: `/usr/share/myos/stack`,
`/usr/local/share/myos/stack`, `~/.local/share/myos/stack`, `../stack`,
`./stack`. A stack present in several of them is merged: the project refines
the catalogue.

## Write a stack

A stack is a directory holding compose files and what makes them usable
without editing anything:

```
stack/myapp/
  myapp.yml                the compose file (and myapp.<env>.yml, myapp.<suffix>.yml overlays)
  .env.dist                what the user must provide, with computed defaults, rendered once into .env
  myapp.settings           computed defaults, recomputed on every run (see lib/settings.awk)
  myapp.env                plain defaults, and the groups (name=member member)
  actions/pre-backup       a hook: quiesce the database before its volume is archived
  justfile                 the same hooks as just recipes, when just is installed
  docker/<image>/Dockerfile   images `myos build` builds
```

The values of the user always win: command line, environment, `$WORKDIR/.env`,
then the defaults of the stack, then the engine's own defaults
(`share/settings/engine.settings`, written in the same language).

## Develop

```sh
make test              # golden (recorded behaviour), verbs (against the docker mock), unit
make lint              # shellcheck
make test-portability  # the golden suite under the sh of Alpine and Debian, in docker
```

The expectations of `spec/golden/expected/` were first recorded from the GNU
make engine this tool grew out of (tag `legacy-1.0-beta`); every difference of
the rewrite is written down in `spec/golden/DELTAS.md`. `AGENTS.md` says how
to change the engine; `skills/myos/` teaches an agent how to use it.

## License

GPL-3.0, see `LICENSE`.
