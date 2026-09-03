# myos, for agents working on this repository

myos runs docker compose stacks. `skills/myos/SKILL.md` explains how to *use*
it; this file is about changing it.

## Check your work

```sh
make test     # unit + golden, both engines, docker is mocked
make lint     # shellcheck
```

Golden tests compare the output of the CLI **and** of the legacy make engine
against recordings made at the tag `legacy-1.0-beta`. If a change moves an
output on purpose, record the CLI expectation in `spec/golden/expected.cli/`
and write down why in `spec/golden/DELTAS.md`. Never edit
`spec/golden/expected/` by hand: it is the behaviour of the old engine.

## Layout

See `skills/myos/references/authoring.md`. In short: `bin/myos` parses and
dispatches, `lib/*.sh` holds one concern each, `lib/cmd/<name>.sh` holds one
command each, `share/compose/` holds the two overlays the framework itself
provides, and the stacks live in another repository, `myos-stacks`.

## Shell constraints

POSIX shell only: this runs on the bash 3.2 of macOS and on Alpine. No `local`,
no arrays, no `[[`. Two traps already paid for:

- `[a-z]` in a `case` pattern also matches uppercase under a `fr_FR` collation;
  use `[:lower:]`.
- a function called inside `$( )` cannot return anything through a global.

## Do not

- Reintroduce a `stack/` or `docker/` directory here: they belong to
  `myos-stacks`.
- Make an unknown command or an unknown stack succeed silently.
- Change a default project name without an entry in `DELTAS.md` and a note in
  the skill: it renames the containers and volumes of every deployment.
