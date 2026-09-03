# Intentional differences between the legacy make engine and the bash CLI

Golden expectations in `expected/` are recorded from the legacy engine
(git tag `legacy-1.0-beta`). When the CLI intentionally behaves differently the
case gets an override in `expected.cli/<case>.txt` and a line here.
`make test-golden MYOS_ENGINE=cli` checks the CLI against those overrides.

## Shape of the output

| what | legacy | cli |
|---|---|---|
| sub-make line | every command is preceded by the recursive `make ... docker-compose-up STACK=...` it re-enters | no recursion, so no such line |
| compose invocation | `docker --log-level=error compose --ansi=auto -f ... -p ...` | `docker compose -f ... -p ... --project-directory <dir of the first file>` |
| several stacks in one project | one `docker compose up` per stack, each with the full file list, so N stacks meant N identical calls | a single call per project |
| network creation | `sh -c docker network create <n> >/dev/null 2>&1` on every up | `docker network create <n>`, only when the network is missing |
| unknown command | prints a warning and exits 0 | prints an error and exits 2 |
| unknown stack | silently resolves to nothing and exits 0 | exits 3 with the search path |

## Values

| what | legacy | cli | why |
|---|---|---|---|
| `APP` in wrapper mode | `myos`, the framework directory itself | the stack, or the directory being run | the legacy value described the framework, not the thing being deployed. The real `up` path already passed `APP_NAME=<stack>` to its sub-make, so the CLI matches what actually ran; only the `print-` target disagreed. |
| `COMPOSE_PROJECT_NAME` for a catalogue stack in wrapper mode | `<user>-myos-<env>` for every stack | `<user>-<env>-<stack>` | same reason: two different stacks shared one project name when printed, but not when run |
| `COMPOSE_PROJECT_NAME` default order | `<user>-<app>-<env>` | `<user>-<env>-<app>` | environments are shared across apps, so the environment reads better in the middle. `MYOS_PROJECT_FORMAT=user-app-env` restores the old order and is what `myos migrate pin` writes into existing deployments. |
| compose files of the current directory | ignored in wrapper mode: only a `STACK` was ever loaded | loaded, as a stack named after the directory | this is the point of unifying the two modes |
| overlay order for several suffixes | the order the `COMPOSE_FILE_*` variables happened to be declared in | sorted by suffix name | a compose overlay wins over the ones before it, so the order has to be predictable rather than depend on where a variable was set |
| framework overlays | `stack/myos/*.yml` | `share/compose/*.yml` | the catalogue moved to myos-stacks; these files stay with the framework |

## Tag helpers

| case | delta | why |
|---|---|---|
| `myos_urlprefix` with several uris | the bash port joins tags with `,`, the make macro emits `tag ,tag` | the make template ends with ` $(2)` (options), so an empty option list leaves a space before the comma. Harmless but sloppy; every tag written by hand on the fleet uses the clean form. |
| `myos_urlprefix` with options passed inside the path argument | the bash port keeps `*` right after the path (`urlprefix-host:443/* proto=https`), the make macro appends it after the options (`urlprefix-host:443/ proto=https*`) | only reachable by stuffing options into argument 1, which the stale example in `make/apps/def.mk` did. Through `tagprefix`, the real code path, both engines agree. |
