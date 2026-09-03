# Writing a stack, and working on myos

## A new stack in the catalogue

```
stack/<name>/<name>.yml          the services
stack/<name>/<name>.local.yml    what only makes sense on a workstation (published ports…)
stack/<name>/<name>.labels.yml   the registrator labels, so routing stays optional
stack/<name>/<name>.env          plain settings: versions, defaults
stack/<name>/<name>.sh           computed settings (fabio tags), no make needed
stack/<name>/.env.dist           the variables it expects, with defaults
stack/<name>/README.md           what it is and what it needs
```

Rules that keep a stack reusable:
- no `container_name`, except in a `host/` stack: it prevents scaling and
  collides between users,
- no fixed host port outside `host/`; publish through the load balancer,
- reference variables with a default: `${POSTGRES_VERSION:-16}`,
- attach to `private` to be reachable by the other stacks of the user, to
  `public` to be routed,
- name volumes, never bind-mount an absolute path.

Check it before committing:

```sh
myos -n config <name>     # the file list and the project
myos config <name>        # the rendered yaml
```

## A group

```sh
# stack/<group>.env
mygroup=<name> other/<name>
```

Lowercase, and it may name other groups.

## Working on myos itself

```sh
make test               # unit + golden, against both engines, with a mocked docker
make test-golden        # golden only
make golden-record      # re-record the golden expectations from the make engine
make lint               # shellcheck
```

Layout:

```
bin/myos          argument parsing, configuration, dispatch
lib/core.sh       logging, exit codes, dry run
lib/str.sh        strings and version comparison
lib/naming.sh     project names, networks, user identity
lib/stack.sh      stack path, references, overlays, groups
lib/config.sh     dotenv, variables of the compose files
lib/compose.sh    finding and calling docker compose
lib/tags.sh       fabio tags
lib/cmd/<x>.sh    one file per command
share/compose/    the networks and volumes overlays myos provides
spec/             shellspec
```

Adding a command: write `lib/cmd/<name>.sh` defining `myos_cmd_<name>`, add it
to the usage text in `bin/myos`, and cover it in `spec/unit`.

Constraints:
- POSIX shell, no bashisms: it has to run under the bash 3.2 of macOS and the
  ash of Alpine. `make test` runs on both.
- No `a-z` ranges in a `case` pattern: under a dictionary collation such as
  `fr_FR` they also match uppercase. Use `[:lower:]`.
- A function that has to return several values takes them out through printf,
  not through a global: a caller inside `$( )` would lose the global.
- Changing what a command prints means updating `spec/golden/expected*/` and
  explaining the change in `spec/golden/DELTAS.md`.
