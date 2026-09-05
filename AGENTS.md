# myos, for agents working on this repository

myos runs docker compose stacks. `skills/myos/SKILL.md` explains how to *use*
it; this file is about changing it.

## Check your work

```sh
make test              # golden + verbs + unit, docker is mocked
make lint              # shellcheck
make test-portability  # the golden suite under the sh of Alpine and Debian (docker)
spec/support/try.sh host-project -n up host   # one command on a fixture, normalized
```

The golden suite (`spec/golden/`) is the contract: `cases.txt` lists commands,
`expected/` their output. Never edit an expectation by hand: change the code,
run `make golden-record CASES="name ..."`, read the diff, and write down in
`spec/golden/DELTAS.md` why the behaviour moved. The verbs without a recorded
history (backup, restore, upgrade, doctor, firewall, cert, status) are
specified in `spec/verbs/` against the docker mock of `spec/support/bin/`.

## Layout

`myos` (wrapper: symlinks, system config) -> `lib/main.sh` (arguments,
chaining, dispatch) -> `lib/path.sh ref.sh files.sh stack.sh` (where a stack
is, which files, which project) -> `lib/values.sh settings.sh settings.awk
fn.sh env.sh` (the layers of values, the `.settings` compiler, the routing
functions, the `.env.dist` rendering) -> `lib/verb/*.sh` (one file per verb)
with `lib/hooks.sh events.sh lock.sh`. `share/settings/engine.settings` holds
the engine's own defaults in the language of the stacks; `share/compose/` the
two overlays it adds (networks, volumes). `justfile` is the interface for
`just --list` and the model of the hooks a stack ships.

## Shell constraints

POSIX sh only (dash, busybox ash, bash 3.2): no `local`, no arrays, no `[[`.
A function returns through `R`, never through `$( )`; every temporary is
prefixed with a tag of its function (`_p_` in `myos_path`...), because nested
calls share the same namespace. Word lists are iterated with `set -f` (a word
may be `*.example.org`). Traps already paid for: `[a-z]` matches uppercase
under `fr_FR`; `${*#pat}` applies to each parameter; a `grep` without file
argument reads stdin; `env A=1 'docker --x=y'` reads the command as an
assignment; a `#` in a make line starts a comment.

## Do not

- Reintroduce a `stack/` or `docker/` directory here: they belong to
  `myos-stacks`; `spec/fixtures/catalogue` is a frozen copy for the tests.
- Make an unknown verb or an unknown stack succeed silently.
- Change a default project name without an entry in `DELTAS.md` and a note in
  the skill: it renames the containers and volumes of every deployment.
- Put anything machine-dependent in an expectation: `myos_normalize` masks
  paths, ids, dates, git state and credentials; extend it rather than record
  them.
